#!/usr/bin/env bash
msbatch=$("$scriptdir/hierma_getparm.sh" msbatch)

choice=$(dialog --title "HIERMA" --menu 'Select the time zone that will be used for the installation.' 23 78 18 \
'GMT' '(GMT) Greenwich Mean Time; Dublin, Edinburgh, London, Lisbon' \
'Greenwich' '(GMT) Monrovia, Casablanca' \
'Azores' '(GMT-01:00) Azores, Cape Verde Is.' \
'Mid-Atlantic' '(GMT-02:00) Mid-Atlantic' \
'Newfoundland' '(GMT-03:30) Newfoundland' \
'SA Eastern' '(GMT-03:00) Buenos Aires, Georgetown' \
'E. South America' '(GMT-03:00) Brasilia' \
'SA Western' '(GMT-04:00) Caracas, La Paz' \
'Atlantic' '(GMT-04:00) Atlantic Time (Canada)' \
'US Eastern' '(GMT-05:00) Indiana (East)' \
'Eastern' '(GMT-05:00) Eastern Time (US & Canada)' \
'SA Pacific' '(GMT-05:00) Bogota, Lima' \
'Canada Central' '(GMT-06:00) Saskatchewan' \
'Mexico' '(GMT-06:00) Mexico City' \
'Central' '(GMT-06:00) Central Time (US & Canada)' \
'Mountain' '(GMT-07:00) Mountain Time (US & Canada)' \
'US Mountain' '(GMT-07:00) Arizona' \
'Pacific' '(GMT-08:00) Pacific Time (US & Canada); Tijuana' \
'Alaskan' '(GMT-09:00) Alaska' \
'Hawaiian' '(GMT-10:00) Hawaii' \
'Samoa' '(GMT-11:00) Midway Island, Samoa' \
'Dateline' '(GMT-12:00) Eniwetok, Kwajalein' \
'W. Europe' '(GMT+01:00) Berlin, Stockholm, Rome, Bern, Brussels, Vienna, Amsterdam' \
'Romance' '(GMT+01:00) Paris, Madrid' \
'Prague Bratislava' '(GMT+01:00) Prague, Bratislava' \
'Warsaw' '(GMT+01:00) Warsaw' \
'GFT' '(GMT+02:00) Athens, Helsinki, Istanbul' \
'Egypt' '(GMT+02:00) Cairo' \
'E. Europe' '(GMT+02:00) Eastern Europe' \
'South Africa' '(GMT+02:00) Harare, Pretoria' \
'Israel' '(GMT+02:00) Israel' \
'Saudi Arabia' '(GMT+03:00) Baghdad, Kuwait, Nairobi, Riyadh' \
'Russian' '(GMT+03:00) Moscow, St. Petersburg' \
'Iran' '(GMT+03:30) Tehran' \
'Arabian' '(GMT+04:00) Abu Dhabi, Muscat, Tbilisi, Kazan, Volgograd' \
'Afghanistan' '(GMT+04:30) Kabul' \
'West Asia' '(GMT+05:00) Islamabad, Karachi, Ekaterinburg, Tashkent' \
'India' '(GMT+05:30) Bombay, Calcutta, Madras, New Delhi, Colombo' \
'Central Asia' '(GMT+06:00) Almaty, Dhaka' \
'Bangkok' '(GMT+07:00) Bangkok, Jakarta, Hanoi' \
'Beijing' '(GMT+08:00) Beijing, Chongqing, Urumqi' \
'Taipei' '(GMT+08:00) Hong Kong, Perth, Singapore, Taipei' \
'Tokyo' '(GMT+09:00) Tokyo, Osaka, Sapporo, Seoul, Yakutsk' \
'Cen. Australia' '(GMT+09:30) Adelaide' \
'AUS Central' '(GMT+09:30) Darwin' \
'E. Australia' '(GMT+10:00) Brisbane' \
'AUS Eastern' '(GMT+10:00) Canberra, Melbourne, Sydney' \
'West Pacific' '(GMT+10:00) Guam, Port Moresby, Vladivostok' \
'Tasmania' '(GMT+10:00) Hobart' \
'Central Pacific' '(GMT+11:00) Magadan, Solomon Is., New Caledonia' \
'Fiji' '(GMT+12:00) Fiji, Kamchatka, Marshall Is.' \
'New Zealand' '(GMT+12:00) Wellington, Auckland' \
    3>&1 1>&2 2>&3)
if [ $? = 0 ]; then
    "$scriptdir/hierma_setparm.sh" tz "$choice"
fi
