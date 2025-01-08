SmartPrompt.define_worker :check_news_type do  
  use "siliconflow"
  model "deepseek-ai/DeepSeek-V2.5"
  prompt :analyzing_news_type, {news_text: params[:news_text]}
  safe_send_msg
end