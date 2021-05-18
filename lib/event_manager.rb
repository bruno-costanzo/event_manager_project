require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

puts 'EventManager initialized.'

contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
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

def clean_phone_number(phone)
  phone.gsub!(/[^\d]/, '')
  if phone.length == 11 && phone[0] == '1' || phone.length == 10
    phone = phone[1..10] unless phone.length == 10
    phone
  else
    'Bad number'
  end
end

def best_hour_to_post(times)
  max = '0'
  possible_hours = ('0'..'24').to_a
  possible_hours.each do |time|
    max = time if times.count(time) > times.count(max)
  end
  max
end

def day_to_string(number)
  case number
  when '0'
    'Sunday'
  when '1'
    'Monday'
  when '2'
    'Tuesday'
  when '3'
    'Wednesday'
  when '4'
    'Thursday'
  when '5'
    'Friday'
  when '6'
    'Saturday'
  end
end

def best_day_to_post(days)
  max = '0'
  possible_days = ('0'..'6').to_a
  possible_days.each do |time|
    max = time if days.to_s.count(time) > days.to_s.count(max)
  end
  puts max.class
  day_to_string(max)
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
all_times = []
all_days = []

contents.each do |row|
  id = row[0]

  phone_number = clean_phone_number(row[:homephone])

  name = row[:first_name]

  all_times << Time.strptime(row[:regdate], '%m/%d/%y %H:%M').strftime('%H')

  all_days << Time.strptime(row[:regdate], '%m/%d/%y %H:%M').wday
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

best_time_post = best_hour_to_post(all_times)
best_day_post = best_day_to_post(all_days)