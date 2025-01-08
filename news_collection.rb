require "../smart_prompt/lib/smart_prompt"
require "readline"
require "sequel"
require "io/console"

engine = SmartPrompt::Engine.new("./config/config.yml")
DB = Sequel.connect("postgres://docs:ment@localhost/docs")

class News < Sequel::Model(DB[:news])
end

CATEGORIES = [
  "开源技术", "开源AI", "开源社区生态", "开源软件安全", "开源许可与合规治理",
  "开源商业", "国际协作与开源外交", "开源教育", "开源政策"
].freeze

class Interaction
  def initialize(engine, db)
    @engine = engine
    @db = db
  end

  def start
    puts "欢迎使用开源新闻收集器"
    puts "您可以直接输入新闻URL来收集新闻"
    puts "或输入 'exit' 来退出程序。"

    loop do
      input = Readline.readline("> ", true)
      break if input.nil?
      case input
      when "exit"
        puts "感谢使用,再见!"
        break
      when /http[s]?:\/\/[^\s]+/
        call_llm(input)
      when /.pdf/
        call_llm(input)
      else
        puts "输入合法的URL，请重新输入。"
      end
    end
  end

  def save_to_database(news, url='')
    @db["INSERT INTO news (title, date, summary, category, url) VALUES (?,?,?,?,?)", news[:original_title],news[:date],news[:summary],news[:category], url].insert
    puts "新闻已保存到数据库。"
    puts "-------------------"
  end

  def deduplicate_news(news_list)
    best_news_for_title = {}  
    news_list.each do |news|
      title = news[:original_title].to_s.downcase
      next if title.empty?  
      unless best_news_for_title.key?(title)
        best_news_for_title[title] = news
        next
      end  
      existing_news = best_news_for_title[title]
      current_content_len  = news[:summary].to_s.size
      existing_content_len = existing_news[:summary].to_s.size
      if current_content_len > existing_content_len
        best_news_for_title[title] = news
      end
    end
    best_news_for_title.values
  end

  def call_llm(input)
    if input.end_with?(".pdf") && !input.start_with?("http")
      url = ""
      news_list = @engine.call_worker(:get_news_from_pdf, {text: input})
      news_list = deduplicate_news(news_list)
    else
      url = input
      result = @engine.call_worker(:get_news, {text: input})
      news_list = @engine.call_worker(:parse_json, {text: result})
    end
    news_list.each do |news|
      unless News.find(title: news[:original_title])
        puts <<~NEWS
          原始标题: #{news[:original_title]}
          中文标题: #{news[:chinese_title]}
          日期: #{news[:date]}
          摘要: #{news[:summary]}
          分类: #{news[:category]}
        NEWS
        puts "-------------------"
        loop do
          puts "请输入操作 (S: 保存, D: 丢弃, E: 修改分类, F: 修改日期):"
          input = STDIN.getch.upcase
  
          case input
          when 'S'
            save_to_database(news, url)
            break
          when 'D'
            puts "新闻已丢弃。"
            puts "-------------------"
            break
          when 'E'
            puts "请选择一个新的分类："
            CATEGORIES.each_with_index do |category, index|
              puts "#{index + 1}. #{category}"
            end
            print "输入分类编号: "
            category_index = STDIN.getch.to_i - 1
            if category_index.between?(0, CATEGORIES.length - 1)
              news[:category] = CATEGORIES[category_index]
              puts "分类已修改为: #{news[:category]}"
              # save_to_database(news)
              # break
            else
              puts "无效的编号，请重新输入。"
            end
          when 'F'
            print "请输入新的日期: "
            news[:date] = STDIN.gets.chomp
            puts "日期已修改为: #{news[:date]}"
            # save_to_database(news)
            # break
          else
            puts "无效输入，请重新输入。"
          end
        end
      end 
    end
  end
end

Interaction.new(engine, DB).start