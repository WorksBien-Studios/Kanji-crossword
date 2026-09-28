# -*- coding: utf-8 -*-
"""Solver-derived difficulty metrics for chain-layout Nankuro puzzles."""
from __future__ import annotations

from collections import defaultdict, deque
from math import log2


def _number_graph(records, cell_to_num):
    graph = defaultdict(set)
    for _, cells in records:
        nums = [cell_to_num[cell] for cell in cells]
        for num in nums:
            graph[num]
        for a, b in zip(nums, nums[1:]):
            if a != b:
                graph[a].add(b)
                graph[b].add(a)
    return graph


def _distance_metrics(graph, starters):
    if not graph:
        return 0, 0.0
    seeds = [num for num in starters if num in graph]
    if not seeds:
        return len(graph), float(len(graph))
    distances = {num: 0 for num in seeds}
    q = deque(seeds)
    while q:
        cur = q.popleft()
        for nxt in graph[cur]:
            if nxt not in distances:
                distances[nxt] = distances[cur] + 1
                q.append(nxt)
    missing = len(graph) - len(distances)
    max_depth = max(distances.values(), default=0) + (len(graph) if missing else 0)
    avg_depth = (
        sum(distances.values()) + missing * len(graph)
    ) / max(1, len(graph))
    return max_depth, avg_depth


def _branching_pressure(records, restricted_words):
    by_pos = [defaultdict(int), defaultdict(int)]
    for word in restricted_words:
        if len(word) != 2:
            continue
        by_pos[0][word[0]] += 1
        by_pos[1][word[1]] += 1

    pressures = []
    for word, _ in records:
        if len(word) != 2:
            continue
        candidate_count = min(by_pos[0][word[0]], by_pos[1][word[1]])
        pressures.append(log2(max(1, candidate_count)))
    if not pressures:
        return 0.0
    return sum(pressures) / len(pressures)


def compute_difficulty(records, cell_to_num, starters, restricted_words):
    graph = _number_graph(records, cell_to_num)
    number_count = max(1, len(graph))
    starter_count = len(starters)
    clue_scarcity = 1.0 - min(1.0, starter_count / number_count)

    max_depth, avg_depth = _distance_metrics(graph, starters)
    depth_norm = min(1.0, max_depth / 10.0)
    avg_depth_norm = min(1.0, avg_depth / 6.0)

    branch_bits = _branching_pressure(records, restricted_words)
    branch_norm = min(1.0, branch_bits / 4.0)

    score = (
        0.45 * clue_scarcity
        + 0.25 * depth_norm
        + 0.15 * avg_depth_norm
        + 0.15 * branch_norm
    )
    metrics = {
        "clueScarcity": round(clue_scarcity, 4),
        "maxLogicDepth": int(max_depth),
        "averageLogicDepth": round(avg_depth, 4),
        "branchingBits": round(branch_bits, 4),
    }
    return round(min(1.0, max(0.0, score)), 4), metrics
