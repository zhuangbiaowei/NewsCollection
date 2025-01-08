SmartPrompt.define_worker :get_news_from_pdf do
  file_path = params[:text]  
  text = call_worker(:pdf_to_text, {file: file_path})
  use "siliconflow"
  # use "ollama"

  sys_msg "You're a journalist familiar with open source-related news coverage."
  news_list = []  
  pages = text.split("\n--- End of Page ---\n")
  5.upto(pages.size-1) do |i|
    puts "page #{i}"
    pages[i] = pages[i].split("\n")[1..-1].join("\n")
    model "Qwen/Qwen2.5-Coder-7B-Instruct"
    # model "qwen2.5-coder:14b"
    # news_type = call_worker(:check_news_type, {news_text: pages[i]})
    # puts "--------新闻类型：#{news_type}---------"
    # if news_type == "正文"
    prompt :analyzing_news_content, {news: pages[i]}
    news_text = safe_send_msg
    prompt :cleanup_content, {format: "json", text: news_text}
    news_json_str = safe_send_msg
    news_json = call_worker(:parse_json, {text: news_json_str})
    news_list.concat(news_json) 
    sleep(1)
    # else
    #  puts pages[i]
    # end
  end
  news_list
end
