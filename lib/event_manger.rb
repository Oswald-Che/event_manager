require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyD_6Jl26CCQOQFQYrxPfQMFA6QlW7AT2pw'


def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_number(number)
  number = number.delete('^0-9')
  if !number.length.between?(10, 11) || (number.length == 11 && number[0] != '1')
    number = 'Bad Number'
  elsif number.length == 11
    number = number[1..10]
  end

  number

end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_count = Hash.new(0)
day_count = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  date = DateTime.strptime(row[:regdate], '%m/%d/%Y %k:%M')
  number = clean_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  hour_count[date.hour] += 1
  day_count[date.strftime('%A')] += 1

  puts "#{number}"
  save_thank_you_letter(id, form_letter)
end

puts "The most frequent hour is #{hour_count.max_by(&:last).first}"
puts "The most frequent day is #{day_count.max_by(&:last).first}"