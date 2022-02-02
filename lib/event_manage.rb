require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'


def clean_zipcode(zipcode)
  if zipcode.nil?
    zipcode = '00000'
  elsif zipcode.length < 5
    zipcode = zipcode.rjust(5, '0')
  elsif zipcode.length > 5
    zipcode = zipcode[0..4]
  end
  return zipcode
end

def clean_phone_numbers(phone_number)
  # strip dashes and spaces from number
  if phone_number.nil?
    return '0000000000'
  else
    phone_number.tr!('-', '')
	phone_number.tr!(' ', '')
    if phone_number.length >= 10 and phone_number.length <= 11
      if phone_number.length == 11
	    if phone_number[0] == 1
	      phone_number = phone_number[1..]
		  return phone_number
	    else
	      phone_number = '00000000000'
	    end
	  elsif phone_number.length == 10
	    return phone_number
	  end
    else
      phone_number = '0000000000'
    end
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
  begin
      legislators = civic_info.representative_info_by_address(
	    address: zipcode,
	    levels: 'country',
	    roles: ['legislatorUpperBody', 'legislatorLowerBody']
    	)

	  legislators = legislators.officials

	  return legislators
  rescue
      'You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('../output') unless Dir.exist?('../output')

  filename = "../output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def get_most_popular_time(hourCount)
  # getting the max date count to see when the most popular time to sign up
  mostPopularHour = hourCount.max_by{|key, value| value}[0]
  hourSuffix = "AM"
  if mostPopularHour > 12
    hourSuffix = "PM"
    mostPopularHour -= 12
  end
  return [mostPopularHour, hourSuffix]
end

puts "Event Manager Initialized!"

contents = CSV.open('../event_attendees.csv', 
                    headers: true,
					header_converters: :symbol)

template_letter = File.read('../form_letter.erb')
erb_template = ERB.new(template_letter)

hourCount = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_numbers(row[:homephone])

  regDate = row[:regdate]

  date = DateTime.strptime(regDate, '%m/%d/%y %H:%M') 

  if hourCount.key?(date.hour)
    hourCount[date.hour] += 1
  else
    hourCount[date.hour] = 0
  end

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id, form_letter)
end

popHour = get_most_popular_time(hourCount)
puts "The most popular hour to register is #{popHour[0]}:00 #{popHour[1]}"





