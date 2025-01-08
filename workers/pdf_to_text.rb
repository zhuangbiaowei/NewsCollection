require 'pdf-reader'

SmartPrompt.define_worker :pdf_to_text do
  text = ""
  reader = PDF::Reader.new(params[:file])  
  reader.pages.each do |page|
    text = text + page.text
    text = text + "\n--- End of Page ---\n"
  end
  text
end