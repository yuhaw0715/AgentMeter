cask "agentmeter" do
  version "0.1.0"
  sha256 :no_check

  url "https://github.com/yuhaw0715/AgentMeter/releases/download/v#{version}/AgentMeter-v#{version}.zip"
  name "AgentMeter"
  desc "Lightweight, native macOS rate-limit monitor for AI Coding Agents (ChatGPT Codex)"
  homepage "https://github.com/yuhaw0715/AgentMeter"

  depends_on macos: ">= :sequoia"

  app "AgentMeter.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-d", "com.apple.quarantine", "#{appdir}/AgentMeter.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/com.agentmeter.AgentMeter",
    "~/Library/Caches/com.agentmeter.AgentMeter",
    "~/Library/Preferences/com.agentmeter.AgentMeter.plist",
    "~/Library/Saved Application State/com.agentmeter.AgentMeter.savedState"
  ]
end
