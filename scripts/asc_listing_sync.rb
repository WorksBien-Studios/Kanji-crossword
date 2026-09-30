#!/usr/bin/env ruby

require "bigdecimal"
require "date"
require "json"
require "net/http"
require "open3"
require "uri"

API = "https://api.appstoreconnect.apple.com"

def required_env(name)
  value = ENV[name].to_s.strip
  abort "Missing #{name}." if value.empty?
  value
end

KEY_PATH = required_env("ASC_KEY_PATH")
KEY_ID = required_env("ASC_KEY_ID")
ISSUER_ID = required_env("ASC_ISSUER_ID")
APP_ID = required_env("ASC_APP_ID")
BUNDLE_ID = required_env("IOS_BUNDLE_ID")
MANIFEST_PATH = ENV.fetch("MANIFEST_PATH", "app-store/LISTING_MANIFEST.json")
MANIFEST = JSON.parse(File.read(MANIFEST_PATH, encoding: "UTF-8"))

def token
  script = File.expand_path("asc_jwt.rb", __dir__)
  jwt, status = Open3.capture2("ruby", script, KEY_PATH, KEY_ID, ISSUER_ID)
  abort "JWT generation failed." unless status.success?
  jwt.strip
end

def request(method, path, body: nil, allow: [])
  uri = URI.join(API, path)
  klass = {
    get: Net::HTTP::Get,
    post: Net::HTTP::Post,
    patch: Net::HTTP::Patch
  }.fetch(method)
  req = klass.new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Content-Type"] = "application/json" if body
  req.body = JSON.generate(body) if body
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  code = response.code.to_i
  return [code, response.body] if code.between?(200, 299) || allow.include?(code)
  abort "App Store Connect #{method.to_s.upcase} #{path} failed with HTTP #{code}: #{response.body}"
end

def get_json(path, allow_missing: false)
  code, body = request(:get, path, allow: allow_missing ? [404] : [])
  return {} if code == 404
  JSON.parse(body)
end

def query(path, params)
  "#{path}?#{URI.encode_www_form(params)}"
end

def patch_resource(path, type, id, attributes)
  request(:patch, path, body: {
    data: { type: type, id: id, attributes: attributes }
  })
end

def reachable?(url)
  current = URI(url)
  6.times do
    response = Net::HTTP.start(
      current.hostname,
      current.port,
      use_ssl: current.scheme == "https",
      open_timeout: 10,
      read_timeout: 20
    ) { |http| http.request(Net::HTTP::Get.new(current)) }
    return true if response.code.to_i.between?(200, 299)
    if response.is_a?(Net::HTTPRedirection) && response["location"]
      current = URI.join(current, response["location"])
      next
    end
    return false
  end
  false
rescue StandardError
  false
end

locale = MANIFEST.fetch("locales").first
%w[marketing_url support_url privacy_url].each do |field|
  url = locale.fetch(field)
  ok = false
  18.times do
    if reachable?(url)
      ok = true
      break
    end
    sleep 10
  end
  abort "Public URL did not become reachable: #{url}" unless ok
end

app = get_json("/v1/apps/#{APP_ID}").fetch("data")
abort "Mapped bundle ID mismatch." unless app.dig("attributes", "bundleId") == BUNDLE_ID
patch_resource(
  "/v1/apps/#{APP_ID}",
  "apps",
  APP_ID,
  {
    primaryLocale: MANIFEST.dig("app", "primary_locale"),
    contentRightsDeclaration: MANIFEST.dig("app", "content_rights_declaration")
  }
)

custom_eula = get_json("/v1/apps/#{APP_ID}/endUserLicenseAgreement", allow_missing: true)
abort "A custom EULA exists, but the manifest requires Apple's Standard EULA." if custom_eula["data"]

version_query = query(
  "/v1/apps/#{APP_ID}/appStoreVersions",
  "filter[platform]" => "IOS",
  "filter[versionString]" => MANIFEST.dig("app", "version"),
  "limit" => "20"
)
versions = get_json(version_query).fetch("data")
editable_states = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED]
versions = versions.select { |item| editable_states.include?(item.dig("attributes", "appStoreState")) }
abort "Expected exactly one editable app version; found #{versions.length}." unless versions.length == 1
version_id = versions.first.fetch("id")
patch_resource(
  "/v1/appStoreVersions/#{version_id}",
  "appStoreVersions",
  version_id,
  {
    copyright: "2026 #{MANIFEST.dig("app", "company_name")}",
    releaseType: MANIFEST.dig("app", "release_type")
  }
)

review = get_json("/v1/appStoreVersions/#{version_id}/appStoreReviewDetail", allow_missing: true)
review_attributes = {
  demoAccountRequired: false,
  demoAccountName: nil,
  demoAccountPassword: nil,
  notes: MANIFEST.dig("review", "notes")
}
if review["data"]
  review_id = review["data"].fetch("id")
  patch_resource(
    "/v1/appStoreReviewDetails/#{review_id}",
    "appStoreReviewDetails",
    review_id,
    review_attributes
  )
else
  _code, body = request(:post, "/v1/appStoreReviewDetails", body: {
    data: {
      type: "appStoreReviewDetails",
      attributes: review_attributes,
      relationships: {
        appStoreVersion: {
          data: { type: "appStoreVersions", id: version_id }
        }
      }
    }
  })
  review_id = JSON.parse(body).fetch("data").fetch("id")
end
review_live = get_json("/v1/appStoreReviewDetails/#{review_id}").fetch("data").fetch("attributes")
contact_fields = %w[contactFirstName contactLastName contactPhone contactEmail]
missing_contact = contact_fields.reject { |field| !review_live[field].to_s.strip.empty? }
abort "App Review contact is incomplete: #{missing_contact.join(", ")}" unless missing_contact.empty?

app_infos = get_json("/v1/apps/#{APP_ID}/appInfos?limit=200").fetch("data")
active_infos = app_infos.reject { |item| item.dig("attributes", "state") == "REPLACED_WITH_NEW_INFO" }
abort "Expected exactly one active App Info record; found #{active_infos.length}." unless active_infos.length == 1
app_info_id = active_infos.first.fetch("id")
rating = get_json("/v1/appInfos/#{app_info_id}/ageRatingDeclaration", allow_missing: true)
abort "Age rating declaration is unavailable." unless rating["data"]
rating_id = rating["data"].fetch("id")
patch_resource(
  "/v1/ageRatingDeclarations/#{rating_id}",
  "ageRatingDeclarations",
  rating_id,
  MANIFEST.fetch("age_rating")
)

def price_is_active?(attributes)
  today = Date.today
  start_date = attributes["startDate"] && Date.parse(attributes["startDate"])
  end_date = attributes["endDate"] && Date.parse(attributes["endDate"])
  (!start_date || start_date <= today) && (!end_date || end_date >= today)
end

def current_price(schedule_id, resource, price_point_type, territory)
  values = []
  %w[manualPrices automaticPrices].each do |kind|
    path = query(
      "/v1/#{resource}/#{schedule_id}/#{kind}",
      "include" => "#{price_point_type},territory",
      "limit" => "200"
    )
    response = get_json(path)
    included = response.fetch("included", [])
    points = included.select { |item| item["type"] == price_point_type }.to_h { |item| [item["id"], item] }
    response.fetch("data", []).each do |price|
      next unless price_is_active?(price.fetch("attributes", {}))
      territory_id = price.dig("relationships", "territory", "data", "id")
      point_id = price.dig("relationships", price_point_type.sub(/s\z/, ""), "data", "id")
      next unless territory_id == territory && point_id && points[point_id]
      values << points[point_id].dig("attributes", "customerPrice")
    end
  end
  values.compact.last
end

def ensure_app_price(app_id, territory, target)
  schedule = get_json("/v1/apps/#{app_id}/appPriceSchedule", allow_missing: true)
  if schedule["data"]
    amount = current_price(schedule["data"]["id"], "appPriceSchedules", "appPricePoints", territory)
    return if amount && BigDecimal(amount) == BigDecimal(target)
  end
  points_path = query(
    "/v1/apps/#{app_id}/appPricePoints",
    "filter[territory]" => territory,
    "fields[appPricePoints]" => "customerPrice",
    "limit" => "200"
  )
  points = get_json(points_path).fetch("data")
  point = points.find { |item| BigDecimal(item.dig("attributes", "customerPrice")) == BigDecimal(target) }
  abort "No app price point #{target} in #{territory}." unless point
  local_id = "$" + "{price}"
  request(:post, "/v1/appPriceSchedules", body: {
    data: {
      type: "appPriceSchedules",
      relationships: {
        app: { data: { type: "apps", id: app_id } },
        baseTerritory: { data: { type: "territories", id: territory } },
        manualPrices: { data: [{ type: "appPrices", id: local_id }] }
      }
    },
    included: [{
      type: "appPrices",
      id: local_id,
      attributes: { startDate: nil },
      relationships: {
        appPricePoint: { data: { type: "appPricePoints", id: point.fetch("id") } }
      }
    }]
  })
end

download_price = MANIFEST.dig("app", "download_price")
ensure_app_price(APP_ID, download_price.fetch("territory"), download_price.fetch("customer_price"))

territories = get_json("/v1/territories?limit=200").fetch("data").map { |item| item.fetch("id") }
wanted_territories = MANIFEST.dig("app", "storefronts")
app_availability = get_json("/v1/apps/#{APP_ID}/appAvailabilityV2", allow_missing: true)
if app_availability["data"]
  availability_id = app_availability["data"].fetch("id")
  abort "New territories are enabled; Japan-only launch cannot be guaranteed." if app_availability["data"].dig("attributes", "availableInNewTerritories")
  rows = get_json(query(
    "/v2/appAvailabilities/#{availability_id}/territoryAvailabilities",
    "include" => "territory",
    "limit" => "200"
  )).fetch("data")
  rows.sort_by { |row| wanted_territories.include?(row.dig("relationships", "territory", "data", "id")) ? 0 : 1 }.each do |row|
    territory_id = row.dig("relationships", "territory", "data", "id")
    wanted = wanted_territories.include?(territory_id)
    next if row.dig("attributes", "available") == wanted
    patch_resource(
      "/v1/territoryAvailabilities/#{row.fetch("id")}",
      "territoryAvailabilities",
      row.fetch("id"),
      { available: wanted, preOrderEnabled: false }
    )
  end
else
  included = territories.each_with_index.map do |territory_id, index|
    {
      type: "territoryAvailabilities",
      id: "$" + "{territory#{index}}",
      attributes: { available: wanted_territories.include?(territory_id), preOrderEnabled: false },
      relationships: {
        territory: { data: { type: "territories", id: territory_id } }
      }
    }
  end
  request(:post, "/v2/appAvailabilities", body: {
    data: {
      type: "appAvailabilities",
      attributes: { availableInNewTerritories: false },
      relationships: {
        app: { data: { type: "apps", id: APP_ID } },
        territoryAvailabilities: {
          data: included.map { |item| { type: item[:type], id: item[:id] } }
        }
      }
    },
    included: included
  })
end

iap_manifest = MANIFEST.dig("app", "in_app_purchase")
iap_query = query(
  "/v1/apps/#{APP_ID}/inAppPurchasesV2",
  "filter[productId]" => iap_manifest.fetch("product_id"),
  "limit" => "2"
)
iaps = get_json(iap_query).fetch("data")
abort "In-app purchase lookup was ambiguous." if iaps.length > 1
if iaps.empty?
  _code, body = request(:post, "/v2/inAppPurchases", body: {
    data: {
      type: "inAppPurchases",
      attributes: {
        name: iap_manifest.fetch("reference_name"),
        productId: iap_manifest.fetch("product_id"),
        inAppPurchaseType: iap_manifest.fetch("type"),
        reviewNote: iap_manifest.fetch("review_note"),
        familySharable: iap_manifest.fetch("family_sharable")
      },
      relationships: {
        app: { data: { type: "apps", id: APP_ID } }
      }
    }
  })
  iap = JSON.parse(body).fetch("data")
else
  iap = iaps.first
  abort "Existing IAP type does not match the manifest." unless iap.dig("attributes", "inAppPurchaseType") == iap_manifest.fetch("type")
  patch_resource(
    "/v2/inAppPurchases/#{iap.fetch("id")}",
    "inAppPurchases",
    iap.fetch("id"),
    {
      name: iap_manifest.fetch("reference_name"),
      reviewNote: iap_manifest.fetch("review_note"),
      familySharable: iap_manifest.fetch("family_sharable")
    }
  )
end
iap_id = iap.fetch("id")

localizations = get_json("/v2/inAppPurchases/#{iap_id}/inAppPurchaseLocalizations?limit=50").fetch("data")
localized = localizations.find { |item| item.dig("attributes", "locale") == iap_manifest.fetch("locale") }
localization_attributes = {
  name: iap_manifest.fetch("display_name"),
  description: iap_manifest.fetch("description")
}
if localized
  patch_resource(
    "/v1/inAppPurchaseLocalizations/#{localized.fetch("id")}",
    "inAppPurchaseLocalizations",
    localized.fetch("id"),
    localization_attributes
  )
else
  request(:post, "/v1/inAppPurchaseLocalizations", body: {
    data: {
      type: "inAppPurchaseLocalizations",
      attributes: localization_attributes.merge(locale: iap_manifest.fetch("locale")),
      relationships: {
        inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } }
      }
    }
  })
end

iap_price = iap_manifest.fetch("price")
schedule = get_json("/v2/inAppPurchases/#{iap_id}/iapPriceSchedule", allow_missing: true)
amount = schedule["data"] && current_price(
  schedule["data"]["id"],
  "inAppPurchasePriceSchedules",
  "inAppPurchasePricePoints",
  iap_price.fetch("territory")
)
unless amount && BigDecimal(amount) == BigDecimal(iap_price.fetch("customer_price"))
  points_path = query(
    "/v2/inAppPurchases/#{iap_id}/pricePoints",
    "filter[territory]" => iap_price.fetch("territory"),
    "limit" => "8000"
  )
  points = get_json(points_path).fetch("data")
  point = points.find { |item| BigDecimal(item.dig("attributes", "customerPrice")) == BigDecimal(iap_price.fetch("customer_price")) }
  abort "No IAP price point #{iap_price.fetch("customer_price")} in #{iap_price.fetch("territory")}." unless point
  local_id = "$" + "{price}"
  request(:post, "/v1/inAppPurchasePriceSchedules", body: {
    data: {
      type: "inAppPurchasePriceSchedules",
      relationships: {
        inAppPurchase: { data: { type: "inAppPurchases", id: iap_id } },
        baseTerritory: { data: { type: "territories", id: iap_price.fetch("territory") } },
        manualPrices: { data: [{ type: "inAppPurchasePrices", id: local_id }] }
      }
    },
    included: [{
      type: "inAppPurchasePrices",
      id: local_id,
      attributes: { startDate: schedule["data"] ? Date.today.iso8601 : nil },
      relationships: {
        inAppPurchasePricePoint: {
          data: { type: "inAppPurchasePricePoints", id: point.fetch("id") }
        }
      }
    }]
  })
end

iap_availability = get_json("/v2/inAppPurchases/#{iap_id}/inAppPurchaseAvailability", allow_missing: true)
unless iap_availability["data"]
  request(:post, "/v1/inAppPurchaseAvailabilities", body: {
    data: {
      type: "inAppPurchaseAvailabilities",
      attributes: { availableInNewTerritories: false },
      relationships: {
        inAppPurchase: { data: { type: "inAppPurchases", id: iap_id } },
        availableTerritories: {
          data: iap_manifest.fetch("available_territories").map { |id| { type: "territories", id: id } }
        }
      }
    }
  })
end

puts JSON.pretty_generate({
  app_id: APP_ID,
  bundle_id: BUNDLE_ID,
  version_id: version_id,
  app_info_id: app_info_id,
  review_detail_id: review_id,
  age_rating_declaration_id: rating_id,
  app_storefronts: wanted_territories,
  app_download_price: download_price,
  iap_id: iap_id,
  iap_product_id: iap_manifest.fetch("product_id"),
  iap_price: iap_price,
  standard_eula: true,
  public_urls_verified: true,
  non_media_sync: "complete"
})
