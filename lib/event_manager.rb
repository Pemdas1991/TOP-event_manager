require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'phonelib'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(phone_number) 

  if Phonelib.valid_for_country?(phone_number, 'US')
    phone_number
  else 
    "Bad Number"
  end

end

def check_time(time)
  Time.strptime(time, "%m/%d/%Y %H:%M")
end

def check_DOW(time)
  #day of week

  case check_time(time).wday
  when 0 
    "Sunday"
  when 1
    "Monday"
  when 2
    "Tuesday"
  when 3
    "Wednesday"
  when 4
    "Thursday"
  when 5
    "Friday"
  when 6
    "Saturday"
  end
end

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

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
regTimes = Hash.new(0)
regDay = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = clean_phone(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  time = row[:regdate]
  legislators = legislators_by_zipcode(zipcode)
  regTimes[check_time(time).hour] += 1
  regDay[check_DOW(time)] += 1


  #puts "#{id}, #{name}, #{number}, #{time}"
  #form_letter = erb_template.result(binding)

  #save_thank_you_letter(id,form_letter)
end

puts regTimes
puts regDay

