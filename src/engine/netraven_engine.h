#ifndef NETRAVEN_ENGINE_H
#define NETRAVEN_ENGINE_H

#include <string>
#include <vector>
#include <map>

namespace netraven {

struct TargetInfo {
    std::string url;
    std::string domain;
    std::string ip;
    std::string server;
    std::string technologies;
    int security_level;
    bool has_waf;
    bool has_https;
};

struct AttackResult {
    std::string attack_type;
    bool success;
    std::string payload_used;
    std::string evidence;
    int confidence;
    std::string recommendation;
};

struct PluginInfo {
    std::string name;
    std::string version;
    std::string author;
    std::string category;
    std::vector<std::string> requires;
    std::string description;
    std::string xml_content;
};

struct EnvDetails {
    std::string current_time;
    std::string working_directory;
    std::string os_version;
    std::string kernel_version;
    std::string arch;
    std::string username;
    std::string hostname;
    std::string cpu_info;
    std::string memory_total;
    std::string memory_free;
    std::string disk_total;
    std::string disk_free;
    std::string python_version;
    std::string gcc_version;
    std::string bash_version;
    std::vector<std::string> loaded_plugins;
    std::vector<std::string> available_tools;
    int active_tunnels;
};

class NetRavenEngine {
public:
    NetRavenEngine();
    ~NetRavenEngine();

    bool initialize();
    bool load_plugin(const std::string& plugin_path);
    bool load_plugin_meta(const std::string& meta_path);
    std::vector<PluginInfo> list_plugins() const;
    bool unload_plugin(const std::string& name);

    TargetInfo analyze_target(const std::string& url);
    std::vector<AttackResult> simulate_sqli(const TargetInfo& target, const std::string& url, const std::string& param);
    std::vector<AttackResult> simulate_xss(const TargetInfo& target, const std::string& url, const std::string& param);
    std::vector<AttackResult> simulate_cmdi(const TargetInfo& target, const std::string& url, const std::string& param);
    std::vector<AttackResult> simulate_lfi(const TargetInfo& target, const std::string& url, const std::string& param);
    std::vector<AttackResult> simulate_bruteforce(const TargetInfo& target, const std::string& service);
    std::vector<AttackResult> simulate_open_redirect(const TargetInfo& target, const std::string& url, const std::string& param);
    std::vector<AttackResult> simulate_csrf(const TargetInfo& target, const std::string& url);
    std::vector<AttackResult> simulate_clickjacking(const TargetInfo& target, const std::string& url);
    std::vector<AttackResult> simulate_crlf(const TargetInfo& target, const std::string& url, const std::string& param);

    EnvDetails get_environment_details() const;
    std::string generate_report(const TargetInfo& target, const std::vector<AttackResult>& results) const;
    double calculate_exploitability_score(const TargetInfo& target) const;

    std::string execute_plugin_attack(const std::string& plugin_name, const std::string& target_url);
    bool create_tunnel(const std::string& local_port, std::string& public_url);
    bool stop_tunnel(const std::string& tunnel_id);
    std::vector<std::string> list_tunnels() const;

    static std::string get_timestamp();
    static std::string to_lower(const std::string& str);
    static std::vector<std::string> split(const std::string& str, char delimiter);

private:
    std::map<std::string, PluginInfo> plugins_;
    std::vector<std::string> active_tunnels_;
    std::string base_work_dir_;

    int calculate_success_probability(const TargetInfo& target, const std::string& attack_type) const;
    std::string generate_payload(const std::string& attack_type, int security_level) const;
    bool detect_evidence(const std::string& response, const std::string& pattern) const;
    void enrich_target_info(TargetInfo& target) const;
    std::string get_security_recommendation(const std::string& attack_type, bool success) const;
};

extern "C" {
    NetRavenEngine* create_engine();
    void destroy_engine(NetRavenEngine* engine);
}

}

#endif