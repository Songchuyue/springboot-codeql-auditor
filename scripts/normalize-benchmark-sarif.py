import copy
import json
import sys
from pathlib import Path

RULE_TAGS = {
    "scy/java/sql-injection": [
        "security",
        "external/cwe/cwe-089",
        "external/cwe/cwe-564",
    ],
    "scy/java/command-injection": [
        "security",
        "external/cwe/cwe-078",
        "external/cwe/cwe-088",
    ],
    "scy/java/path-traversal": [
        "security",
        "external/cwe/cwe-022",
        "external/cwe/cwe-023",
        "external/cwe/cwe-036",
        "external/cwe/cwe-073",
    ],
    "scy/java/xss": [
        "security",
        "external/cwe/cwe-079",
    ],
    "scy/java/log-injection": [
        "security",
        "external/cwe/cwe-117",
    ],
    "scy/java/unsafe-deserialization": [
        "security",
        "external/cwe/cwe-502",
    ],
    "scy/java/ssrf": [
        "security",
        "external/cwe/cwe-918",
    ],
}

def ensure_rule_tags(rule: dict) -> bool:
    rid = rule.get("id")
    if rid not in RULE_TAGS:
        return False
    props = rule.setdefault("properties", {})
    tags = props.setdefault("tags", [])
    for tag in RULE_TAGS[rid]:
        if tag not in tags:
            tags.append(tag)
    return True

def first_uri(result: dict) -> str:
    try:
        return result["locations"][0]["physicalLocation"]["artifactLocation"]["uri"]
    except Exception:
        return ""

def main(inp: str, out: str) -> None:
    data = json.loads(Path(inp).read_text(encoding="utf-8"))

    for run in data.get("runs", []):
        tool = run.setdefault("tool", {})
        driver = tool.setdefault("driver", {})
        driver_rules = driver.setdefault("rules", [])
        driver_rule_ids = {r.get("id") for r in driver_rules if isinstance(r, dict)}

        for rule in driver_rules:
            if isinstance(rule, dict):
                ensure_rule_tags(rule)

        for ext in tool.get("extensions", []) or []:
            for rule in ext.get("rules", []) or []:
                if not isinstance(rule, dict):
                    continue
                if ensure_rule_tags(rule):
                    rid = rule["id"]
                    if rid not in driver_rule_ids:
                        driver_rules.append(copy.deepcopy(rule))
                        driver_rule_ids.add(rid)

        for result in run.get("results", []) or []:
            rid = result.get("ruleId")
            if rid in RULE_TAGS and rid not in driver_rule_ids:
                driver_rules.append({
                    "id": rid,
                    "name": rid,
                    "shortDescription": {"text": rid},
                    "properties": {"tags": RULE_TAGS[rid][:]},
                })
                driver_rule_ids.add(rid)

        for result in run.get("results", []) or []:
            rid = result.get("ruleId", "<no-rule-id>")
            uri = first_uri(result)
            if uri and "BenchmarkTest" not in Path(uri).name:
                print(f"[WARN] Non-Benchmark primary location: {rid} -> {uri}")

    Path(out).write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )
    print(f"[OK] Wrote normalized SARIF to: {out}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python normalize-benchmark-sarif.py <input.sarif> <output.sarif>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])