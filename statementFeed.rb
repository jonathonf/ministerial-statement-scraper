require 'nokogiri'
require 'open-uri'
require 'pony'

@email = "youremail@example.com"

doc = Nokogiri::HTML(open('http://www.parliament.uk/business/publications/hansard/commons/todays-written-statements/')) do |config|
  config.noblanks
end

headings = doc.css("div[@id=ctl00_ctl00_SiteSpecificPlaceholder_PageContent_ctlMainBody_wrapperDiv] h2")
departments = []
statements = []

# Get the 0th to n-1th statements
(headings.length + 1).times do |i|
	items = doc.xpath('//h2['+(i).to_s+']/following-sibling::p') & doc.xpath('//h2['+(i+1).to_s+']/preceding-sibling::p')
	items.each do |item|
		departments.push(headings[i-1])
		statements.push(item)
	end
end

# Get the nth statements
last_statements = doc.xpath('//h2['+headings.length.to_s+']/following-sibling::p')
last_statements.each do |item|
	departments.push(headings.last)
	statements.push(item)
end


# Email
departments.zip(statements).each do |department,statement|
	emailfrom = department.text.strip.gsub(',','').squeeze(" ") + " <rss@parliament.uk>"
	emailsubject = statement.content.gsub(/^\d+\W+|['('].+$/,'')
	emailtext = statement.text.strip.squeeze(" ").gsub(' PDF ','') + "\n" + "http://www.parliament.uk"+statement.child['href']
	puts "Emailing " + emailtext
	Pony.mail(:to => @email, :from => emailfrom,
            :subject => emailsubject, :body => emailtext, :attachments => { statement.child['href']=> "http://www.parliament.uk"+statement.child['href']})
end


