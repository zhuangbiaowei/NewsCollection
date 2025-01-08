require "json"

SmartPrompt.define_worker :parse_json do
  text = params[:text]
  begin
    JSON.parse(text, symbolize_names: true)
  rescue StandardError => e
    text = text.gsub("```json\n", "")
    text = text.gsub("```", "")
  end
  begin
    json = JSON.parse(text, symbolize_names: true)
  rescue StandardError => e
    text = text.match(/(\[.*?\])/m).captures[0] if text.include?("[") && text.include?("]")
  end
  begin
    json = JSON.parse(text, symbolize_names: true)
  rescue  StandardError => e
    puts "无法加载文件, text="
    puts text
    json = []
  end
  json
end