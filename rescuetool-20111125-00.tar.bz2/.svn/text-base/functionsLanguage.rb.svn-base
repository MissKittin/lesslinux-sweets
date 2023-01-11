#!/usr/bin/ruby
# encoding: utf-8

def extract_lang_string(string_id)
	lang = "en"
	lang = LANGUAGE unless LANGUAGE.nil?
	message_string = "message not found: " + string_id
	begin
		message_string = LOCSTRINGS['en'][string_id]
	rescue
	end
	begin
		message_string = LOCSTRINGS[lang][string_id]
	rescue
	end
	return "message not found: " + string_id if message_string.nil?
	return message_string.to_s # .gsub('%BRANDLONG%', get_brandlong)
end

def extract_lang_number(string_id)
	lang = "en"
	lang = LANGUAGE unless LANGUAGE.nil?
	message_string = 0
	begin
		message_string = LOCSTRINGS['en'][string_id]
	rescue
	end
	begin
		message_string = LOCSTRINGS[lang][string_id]
	rescue
	end
	return 0 if message_string.nil?
	return message_string.to_i # .gsub('%BRANDLONG%', get_brandlong)
end