SmartPrompt.define_worker :get_news do
  url = params[:text]
  html = call_worker(:download_page, {url: url})
  text = call_worker(:html_to_text, {html: html})
  use "siliconflow"
  # use "deepseek"
  sys_msg "You're a journalist familiar with open source-related news coverage."
  model "Qwen/Qwen2.5-Coder-32B-Instruct"
  # model "deepseek-chat"
  prompt :analyzing_news_content, {news: text}
  news_text = safe_send_msg  
  prompt :cleanup_content, {format: "json", text: news_text}
  safe_send_msg
end
