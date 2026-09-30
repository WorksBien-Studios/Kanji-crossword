#!/usr/bin/env ruby

require "json"
require "net/http"
require "open3"
require "tempfile"
require "uri"

API = "https://api.appstoreconnect.apple.com"

def required_env(name)
  value = ENV[name].to_s.strip
  abort "Missing #{name}." if value.empty?
  value
end

KEY_ID = required_env("ASC_KEY_ID")
ISSUER_ID = required_env("ASC_ISSUER_ID")
PRIVATE_KEY = required_env("ASC_PRIVATE_KEY")
OLD_APP_ID = required_env("OLD_ASC_APP_ID")
OLD_BETA_GROUP_ID = required_env("OLD_BETA_GROUP_ID")
STALE_TESTER_EMAILS = required_env("STALE_TESTER_EMAILS").split(",").map { |email| email.strip.downcase }.reject(&:empty?)
ABORT_IF_NO_MATCH = ENV.fetch("ABORT_IF_NO_MATCH", "true") == "true"

abort "No stale tester emails supplied." if STALE_TESTER_EMAILS.empty?

def token
  @key_file ||= Tempfile.new(["asc-cleanup-key", ".p8"], binmode: true).tap do |file|
    file.write(PRIVATE_KEY.gsub("\\n", "\n"))
    file.flush
  end

  script = File.expand_path("asc_jwt.rb", __dir__)
  jwt, status = Open3.capture2("ruby", script, @key_file.path, KEY_ID, ISSUER_ID)
  abort "JWT generation failed." unless status.success?
  jwt.strip
end

def request(method, path, body: nil, allow: [])
  uri = URI.join(API, path)
  klass = {
    delete: Net::HTTP::Delete,
    get: Net::HTTP::Get
  }.fetch(method)
  req = klass.new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Content-Type"] = "application/json" if body
  req.body = JSON.generate(body) if body
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  code = response.code.to_i
  return [code, response.body] if code.between?(200, 299) || allow.include?(code)
  abort "App Store Connect #{method.to_s.upcase} #{path} failed with HTTP #{response.code}: #{response.body}"
end

def json_get(path)
  _code, body = request(:get, path)
  JSON.parse(body)
end

def all_pages(path)
  results = []
  next_path = path
  while next_path
    page = json_get(next_path)
    results.concat(page.fetch("data"))
    next_link = page.dig("links", "next")
    next_path = next_link ? next_link.sub(API, "") : nil
  end
  results
end

group_app = json_get("/v1/betaGroups/#{OLD_BETA_GROUP_ID}/app").fetch("data")
abort "Old beta group belongs to #{group_app.fetch("id")}, not #{OLD_APP_ID}." unless group_app.fetch("id") == OLD_APP_ID

testers = all_pages("/v1/betaGroups/#{OLD_BETA_GROUP_ID}/betaTesters?limit=200")
stale_testers = testers.select do |tester|
  email = tester.dig("attributes", "email").to_s.downcase
  STALE_TESTER_EMAILS.include?(email)
end

if stale_testers.empty?
  abort "No matching old beta testers found." if ABORT_IF_NO_MATCH
else
  body = {
    data: stale_testers.map { |tester| { type: "betaTesters", id: tester.fetch("id") } }
  }
  request(:delete, "/v1/betaGroups/#{OLD_BETA_GROUP_ID}/relationships/betaTesters", body: body, allow: [204, 409])
end

builds = all_pages("/v1/betaGroups/#{OLD_BETA_GROUP_ID}/relationships/builds?limit=200")
unless builds.empty?
  body = {
    data: builds.map { |build| { type: "builds", id: build.fetch("id") } }
  }
  request(:delete, "/v1/betaGroups/#{OLD_BETA_GROUP_ID}/relationships/builds", body: body, allow: [204, 409, 422])
end

remaining_testers = all_pages("/v1/betaGroups/#{OLD_BETA_GROUP_ID}/betaTesters?limit=200")
remaining_stale = remaining_testers.select do |tester|
  STALE_TESTER_EMAILS.include?(tester.dig("attributes", "email").to_s.downcase)
end

puts JSON.generate({
  old_app_id: OLD_APP_ID,
  old_beta_group_id: OLD_BETA_GROUP_ID,
  removed_tester_emails: stale_testers.map { |tester| tester.dig("attributes", "email") },
  removed_tester_count: stale_testers.length,
  detached_build_count: builds.length,
  remaining_stale_tester_count: remaining_stale.length,
  decoupled: remaining_stale.empty?
})

abort "Stale testers remain in old beta group." unless remaining_stale.empty?
