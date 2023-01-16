# -*- coding: utf-8 -*-
import os, datetime, binascii, codecs, bisect, re, sys

HEX_LIST = [
"0000", "0001", "0002", "0003", "0004", "0005", "0006", "0007",
"0008", "0009", "000a", "000b", "000c", "000d", "000e", "000f",
"0010", "0011", "0012", "0013", "0014", "0015", "0016", "0017",
"0018", "0019", "001a", "001b", "001c", "001d", "001e", "001f",
"0020", "0021", "0022", "0023", "0024", "0025", "0026", "0027",
"0028", "0029", "002a", "002b", "002c", "002d", "002e", "002f",
"0030", "0031", "0032", "0033", "0034", "0035", "0036", "0037",
"0038", "0039", "003a", "003b", "003c", "003d", "003e", "003f",
"0040", "0041", "0042", "0043", "0044", "0045", "0046", "0047", 
"0048", "0049", "004a", "004b", "004c", "004d", "004e", "004f",   
"0050", "0051", "0052", "0053", "0054", "0055", "0056", "0057",  
"0058", "0059", "005a", "005b", "005c", "005d", "005e", "005f",  
"0060", "0061", "0062", "0063", "0064", "0065", "0066", "0067",  
"0068", "0069", "006a", "006b", "006c", "006d", "006e", "006f",   
"0070", "0071", "0072", "0073", "0074", "0075", "0076", "0077",  
"0078", "0079", "007a", "007b", "007c", "007d", "007e", "007f",
"0080", "0081", "0082", "0083", "0084", "0085", "0086", "0087",
"0088", "0089", "008a", "008b", "008c", "008d", "008e", "008f",
"0090", "0091", "0092", "0093", "0094", "0095", "0096", "0097",
"0098", "0099", "009a", "009b", "009c", "009d", "009e", "009f",
"00a0", "00a1", "00a2", "00a3", "00a4", "00a5", "00a6", "00a7",
"00a8", "00a9", "00aa", "00ab", "00ac", "00ad", "00ae", "00af",
"00b0", "00b1", "00b2", "00b3", "00b4", "00b5", "00b6", "00b7",
"00b8", "00b9", "00ba", "00bb", "00bc", "00bd", "00be", "00bf",
"00c0", "00c1", "00c2", "00c3", "00c4", "00c5", "00c6", "00c7",
"00c8", "00c9", "00ca", "00cb", "00cc", "00cd", "00ce", "00cf",
"00d0", "00d1", "00d2", "00d3", "00d4", "00d5", "00d6", "00d7",
"00d8", "00d9", "00da", "00db", "00dc", "00dd", "00de", "00df",
"00e0", "00e1", "00e2", "00e3", "00e4", "00e5", "00e6", "00e7",
"00e8", "00e9", "00ea", "00eb", "00ec", "00ed", "00ee", "00ef",
"00f0", "00f1", "00f2", "00f3", "00f4", "00f5", "00f6", "00f7",
"00f8", "00f9", "00fa", "00fb", "00fc", "00fd", "00fe", "00ff"
]

HEX = [
"20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "2a", "2b", "2c", "2d", "2e", "2f",
"30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "3a", "3b", "3c", "3d", "3e", "3f",
"40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "4a", "4b", "4c", "4d", "4e", "4f",   
"50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "5a", "5b", "5c", "5d", "5e", "5f",  
"60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "6a", "6b", "6c", "6d", "6e", "6f",   
"70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "7a", "7b", "7c", "7d", "7e", "b0"
]
ASCII = [
" ", "!", '"', "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/",
"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "&lt;", "=", "&gt;", "?",
"@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",   
"P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_",  
"`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",   
"p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", "&#176;",
]

SPECIAL = [u'\xa0', u'\xa1', u'\xa2', u'\xa3', u'\xa4', u'\xa5', u'\xa6', u'\xa7', u'\xa8', u'\xa9', u'\xaa', u'\xab', u'\xac', u'\xad', u'\xae', u'\xaf', u'\xb0', u'\xb1', u'\xb2', u'\xb3', u'\xb4', u'\xb5', u'\xb6', u'\xb7', u'\xb8', u'\xb9', u'\xba', u'\xbb', u'\xbc', u'\xbd', u'\xbe', u'\xbf', u'\xc0', u'\xc1', u'\xc2', u'\xc3', u'\xc4', u'\xc5', u'\xc6', u'\xc7', u'\xc8', u'\xc9', u'\xca', u'\xcb', u'\xcc', u'\xcd', u'\xce', u'\xcf', u'\xd0', u'\xd1', u'\xd2', u'\xd3', u'\xd4', u'\xd5', u'\xd6', u'\xd7', u'\xd8', u'\xd9', u'\xda', u'\xdb', u'\xdc', u'\xdd', u'\xde', u'\xdf', u'\xe0', u'\xe1', u'\xe2', u'\xe3', u'\xe4', u'\xe5', u'\xe6', u'\xe7', u'\xe8', u'\xe9', u'\xea', u'\xeb', u'\xec', u'\xed', u'\xee', u'\xef', u'\xf0', u'\xf1', u'\xf2', u'\xf3', u'\xf4', u'\xf5', u'\xf6', u'\xf7', u'\xf8', u'\xf9', u'\xfa', u'\xfb', u'\xfc', u'\xfd', u'\xfe', u'\xff',"à", "ò", "é", "è", "ì", "í","£" ,"€", "Ä", "Ë", "Ö", "Ü", "ß", "ä", "ë", "ö", "ü"]
SPECIAL_TO_ASCII = ['c2a0', 'c2a1', 'c2a2', 'c2a3', 'c2a4', 'c2a5', 'c2a6', 'c2a7', 'c2a8', 'c2a9', 'c2aa', 'c2ab', 'c2ac', 'c2ad', 'c2ae', 'c2af', 'c2b0', 'c2b1', 'c2b2', 'c2b3', 'c2b4', 'c2b5', 'c2b6', 'c2b7', 'c2b8', 'c2b9', 'c2ba', 'c2bb', 'c2bc', 'c2bd', 'c2be', 'c2bf', 'c380', 'c381', 'c382', 'c383', 'c384', 'c385', 'c386', 'c387', 'c388', 'c389', 'c38a', 'c38b', 'c38c', 'c38d', 'c38e', 'c38f', 'c390', 'c391', 'c392', 'c393', 'c394', 'c395', 'c396', 'c397', 'c398', 'c399', 'c39a', 'c39b', 'c39c', 'c39d', 'c39e', 'c39f', 'c3a0', 'c3a1', 'c3a2', 'c3a3', 'c3a4', 'c3a5', 'c3a6', 'c3a7', 'c3a8', 'c3a9', 'c3aa', 'c3ab', 'c3ac', 'c3ad', 'c3ae', 'c3af', 'c3b0', 'c3b1', 'c3b2', 'c3b3', 'c3b4', 'c3b5', 'c3b6', 'c3b7', 'c3b8', 'c3b9', 'c3ba', 'c3bb', 'c3bc', 'c3bd', 'c3be', 'c3bf',"a0c3", "b2c3", "a9c3", "a8c3", "acc3", "adc3", "a3c2","ac82e2", "84c3", "8bc3", "96c3", "9cc3", "9fc3", "a4c3", "abc3", "b6c3", "bcc3"]

#def date_me():
#    now = datetime.datetime.utcnow()
#    now = datetime.datetime.strptime(str(now), '%Y-%m-%d %H:%M:%S.%f')
#    now = now.strftime('%d-%m-%Y %H.%M.%S')
#    return now

def date_me():
    now = datetime.datetime.utcnow()
    try:
        now = datetime.datetime.strptime(str(now), '%Y-%m-%d %H:%M:%S')
    except:
        now = datetime.datetime.strptime(str(now), '%Y-%m-%d %H:%M:%S.%f')
    try:    
        now = now.strftime('%d-%m-%Y %H.%M.%S')
    except:
        now = now.strftime('%d-%m-%Y %H.%M.%S.%f')    
    return now

DEBUG = False
DEBUG_FOLDER = ""
CSV_FILE = "debug_chatsync.csv"

def set_debug(debug, debug_folder):
     global DEBUG
     global DEBUG_FOLDER
     DEBUG = debug
     DEBUG_FOLDER = debug_folder
     if debug:
          now = date_me()
          print(now+": Debug: ON")
          print(now+": Debug files will be stored here: "+debug_folder)

class Chat(object):
	
    total = 0
	# init
    def __init__(self, user1, user2, chat_id, file_name):
        self.user1 = self.parse_text(user1)
        self.user2 = self.parse_text(user2)
        self.chat_id = chat_id
        self.file_name = file_name
        self.messages = []
        self.check_chat(file_name, user1, user2)
			
	
    def __str__(self):
        rep = self.user1 +" + " +str(self.user2)+ "\n"
        rep = rep
        for message in self.messages:
            rep += str(message) + "  "
		 
        return rep
	

    #Parse text method
    def parse_text(self, value):    
        try:
            value = str(value)
            if "<script" in value:
                value = "<textarea>"+value+"</textarea>"
            if value == "None":
                value = " "
        except UnicodeEncodeError:
            value = value.encode("utf-8")
        return value    			

    def parse_date(self, lines, message_start):
		#Find the timestamp within the file at index message_start-26
        timestamp_end = message_start-26
        timestamp_start = timestamp_end-8
        timestamp = lines[timestamp_start:timestamp_end]
        t1 = timestamp
        hex_temp1 = str(timestamp[6:8])+ str(timestamp[4:6])
        hex_temp2 = str(timestamp[2:4])+ str(timestamp[0:2])
        t2 = hex_temp1+hex_temp2
        try:
            timestamp = int(hex_temp1+hex_temp2, 16)
        except ValueError:
            timestamp = "ERROR"
		
        if timestamp != 0:
            try:
                t3 = timestamp
                timestamp = datetime.datetime.utcfromtimestamp(timestamp)
                timestamp = datetime.datetime.strptime(str(timestamp), '%Y-%m-%d %H:%M:%S')
                timestamp = timestamp.strftime('%d-%m-%Y %H:%M:%S')
                #print t1,t2,t3, timestamp
            except TypeError:
                timestamp = " "
            except ValueError:
				timestamp = "Timestamp out of range: " + str(timestamp)                
        else:
            timestamp = " "        
        return timestamp	
    
    
    def check_chat(self, file_name, user1, user2):
        
        fo = open(file_name, "rb")
        lines = fo.read()
        lines = binascii.hexlify(lines)

        #print file_name
        file_name = file_name[-20:-4]
        if DEBUG:
            debug_counter_finder = open(DEBUG_FOLDER+"debug_counter_"+file_name + "_" + self.user1 + "_"+self.user2 + ".txt", "a+")
        
            debug_file_name = file_name + "_" + self.user1 + "_"+self.user2 + ".txt"
            debug_file = open(DEBUG_FOLDER+debug_file_name, "w")
            header = "initial_length,u_field_length,u_header,u_header_2nd_part,u_id,footer,next_timestamp,next_time_human,next_timestamp_check,message_header,get_hex, \
        bet_hex_and_date_open_tag,bet_hex_and_date_value,bet_hex_and_date_close_tag,check_them,modified_check,len_countX2,count_per_two,count_per_two_hex\n"

            debug_file.write(header)
        
        #print("Check messages behaviour..")
        all_start = "4101050241"
        total_messages = lines.count(all_start)        
        check_them = total_messages
			
        sys.stdout.write(file_name+": checking " +str(check_them) + " messages for a pattern...")
        if total_messages <= 1:
			sys.stdout.write("This chatsync seems empty...skipping\n")
			return 0
		
        check_for_pattern = []
        count = 0
        user_count = 0
        users_table = []
        pattern_this_user = ""
        counting_empty = 0
        offset = 0
        
        #######
        #TODO
        # develop an algorith that check the number of standard messages.
        # if the standard messages are a "GOOD" number, we can say that there won't be a lot of rubbish.
        # Otherwise we should start the cleaning algorithm...
        RUBBISH = 0
        standard_start = "0302"
        standard_mod_start ="0322"
        total_standard_messages = lines.count(standard_start)+ lines.count(standard_mod_start)
        sys.stdout.write("""This chat has """+ str(total_messages) +""" possible messages,
         and the total number of standard messages is """ +str(total_standard_messages)+"\n")
        
		
        while check_them > 0:
			
            count = count + 1
            n=2
            m=4
            
            
            find_the_start = re.search("41[0-9][0-9]05[0-9][0-9]41", lines)
            all_start = str(find_the_start.group(0))

            u_debug_start = find_the_start.group(0)
            
            message_start = lines.find(all_start)
            lines = lines.replace(all_start, "FFFFFFFFFF",1)
             
            find_the_start = re.search("41[0-9][0-9]05[0-9][0-9]41", lines)
            all_start = str(find_the_start.group(0))
            next_message_start = lines.find(all_start)
            initial_length = next_message_start-message_start
            
            #### DEBUG LINE ON ####

            if DEBUG:
                counter_finder = lines[message_start:next_message_start]
                counter_index = counter_finder.index("0404")
                counter_finder = counter_finder[counter_index:]
                c_temp = []
                for s in range(0, len(counter_finder), n):
                    c_temp.append(counter_finder[s:s+2])
                c_temp = str(c_temp).replace("[","").replace("]","")
                debug_counter_finder.write(c_temp+"\n")

            ##### DEBUG LINE OFF #####
            
            next_timestamp_end = next_message_start-16 # 24 is the usual offset
            next_timestamp_start = next_timestamp_end-8 # 8 is the length of a timestamp
            next_timestamp = lines[next_timestamp_start:next_timestamp_end]
            timestamp = self.parse_date(lines, message_start+10)
            next_timestamp_check = lines[next_timestamp_start+6:next_timestamp_end] # get only the byte indicating the year.
            modified_check = str(lines[next_timestamp_start+8:next_timestamp_end+2]) # get only the byte indicating if the message was modified "20" default, modified "40".
            
            
            #print("The year is: "+str(next_timestamp_check)+ " which is equal to 2013..")
            message = lines[message_start:next_timestamp_start]
            user_field_length = message.find("0404")
            footer = ""
            if user_field_length != -1:
                footer = "0404"
            else:
                footer = "not found"	
            u_header_2 = message[10:22]
            if u_header_2[0] == "0":
				u_header_2 = u_header_2[1:]
            user = message[22:user_field_length]
            pattern_this_user = user
            
            if count >= 1:
                after_user = message[user_field_length+154:user_field_length+350]
                
                #print after_user
                if user == pattern_this_user:
					check_for_pattern.append(after_user)
					
            #print users_table, len(users_table)
            get_hex = str(message[-18:-14])
            bet_hex_and_date_open_tag = str(message[-14:-8])
            bet_hex_and_date_value = str(message[-8:-4])
            bet_hex_and_date_close_tag = str(message[-4:])
            message_ending = -18 # find a way to let the algorith calculate this value. For example let him find a pattern between the values above (even different length)
            
            
            #The last message is not separated by the next message (since there is no other message).
            #In this case we should change the original end of the message since the bytes used to show the timestamp
            #of the next message are not existing.
            YEARS = ["3E","40","41","43","45","47","49","4B","4D","4F", "51", "52", "54"] # Years from 2003 to 2015 (#51 is value for 2013) 
            if next_timestamp_check not in YEARS and check_them == 1:
				offset = -10  
                

            message = message[user_field_length+6:message_ending-offset]
            
                        
            status = ""
            
            standard_chat_message = False
            
            message_4_test = "00"+message
            
            m_header = "" # for debug purposes
            
            #check if you can find the standard message start
            #if you find it, then the message will start at that point.
            if "0302" in [message[s:s+m] for s in range(0, len(message), m)]:
                start = message.find("0302")
                #print ("Standard message found, length is "+ str(len(message)))
                m_header = message[start-8:start+4]
                message = message[start:]
                #print ("...now length is "+ str(len(message)))
                standard_chat_message = True
            elif "0302" in [message_4_test[s:s+m] for s in range(0, len(message_4_test), m)]:
                start = message.find("0302")
                #print ("Standard message found, length is "+ str(len(message)))
                m_header = message[start-8:start+4]
                message = message[start:]       
                #print ("...now length is "+ str(len(message)))
                standard_chat_message = True                
            elif "0322" in [message[s:s+m] for s in range(0, len(message), m)]:
                start = message.find("0322")
                #print ("TYPE 1: Possible standard modified message found, length is "+ str(len(message)))
                m_header = message[start-8:start+4]
                message = message[start:]
                #print ("...now length is "+ str(len(message)))
                standard_chat_message = True
                status = "Edit"                                
            elif "0322" in [message_4_test[s:s+m] for s in range(0, len(message_4_test), m)]:
                start = message.find("0322")
                #print ("TYPE 2: Possible standard modified message found, length is "+ str(len(message)))
                m_header = message[start-8:start+4]
                message = message[start:]
                #print message
                #print ("...now length is "+ str(len(message)))
                standard_chat_message = True

                status = "Edit"
					
            
            start_from_the_end = ""
            
            temp = []
            #print message            
            
            for i in range(0, len(message), n):
				temp.append(message[i:i+n])
            #print temp
            
            if standard_chat_message == True:
				try:
					standard_chat_end = temp.index("00")
					if standard_chat_end:
						#print standard_chat_end
						temp = temp[0:standard_chat_end]
						#print temp
				except ValueError:
					empty = "bah!"
					#print ("This message has no standard end '00'...")
						
            #print temp
            z= len(temp)-1
            counting_empty = 0
            for i in range(len(temp)):
				start_from_the_end = start_from_the_end + temp[z]
				z = z -1
            #print start_from_the_end
            file_transfer = "413e05443d0001390000"
            if file_transfer in start_from_the_end:
				#print("yes")
				start_from_the_end = start_from_the_end[len(file_transfer):]
            
            fail_counter = 0
            message_off = 0
            
            def check_the_message(start_from_the_end, m, n):
                count_per_two = ""
                previous = 0
                for i in range(0, len(start_from_the_end), n):
                    #if start_from_the_end[i:i+m] == "7461":
                        #print start_from_the_end
                        #print (start_from_the_end[i:i+n]), (start_from_the_end[i:i+m])
                        #print start_from_the_end[i:i+m]
                    #    revert = start_from_the_end[i:i+m]
                        #print revert
                   #     revert = revert[2:4] + revert[0:2]
                        #print revert[2:4]
                        #print revert[0:2]
                        #print revert
                        #exit(0)
                    if previous == 1:
					    previous = 0
					    continue
                    revert = start_from_the_end[i:i+m]
                    #print revert
                    revert = revert[2:4] + revert[0:2]
                    #if start_from_the_end[i:i+m] == "7461":
                     #   print revert
                      #  exit(0)    
                   # print revert      
                    if revert in SPECIAL_TO_ASCII:
                        #if start_from_the_end[i:i+m] == "7461":
                        
                            #print "revert:"+revert
                        index = SPECIAL_TO_ASCII.index(revert)
                        ascii= SPECIAL[index]
                        previous = 1
                    elif start_from_the_end[i:i+n] in HEX:
                        index = HEX.index(start_from_the_end[i:i+n])
                        ascii= ASCII[index]
                    
                    elif i == 0:
					    retry = 1
					    break
                    else:
                       break
                    count_per_two = ascii+count_per_two
            
            #def check_the_message(start_from_the_end, m, n):
            #    count_per_two = ""
            #    previous = 0
            #    for i in range(0, len(start_from_the_end), n):
            #        #print (start_from_the_end[i:i+n]), (start_from_the_end[i:i+m])
            #        if previous == 1:
			#		    previous = 0
			#		    continue
            #        if start_from_the_end[i:i+n] in HEX:
            #            index = HEX.index(start_from_the_end[i:i+n])
            #            ascii= ASCII[index]
            #        elif start_from_the_end[i:i+m] in SPECIAL:
            #            index = SPECIAL.index(start_from_the_end[i:i+m])
            #            ascii= SPECIAL_TO_ASCII[index]
            #            previous = 1
            #        elif i == 0:
			#		    retry = 1
			#		    break
            #        else:
            #           break
            #        count_per_two = ascii+count_per_two  

                
                if len(count_per_two) != 0:
					return count_per_two, 0
                else:
					return "WARNING: empty message", 1					  	

            
            count_per_two, fail = check_the_message(start_from_the_end,m,n)
            
            fail_counter = fail_counter + fail
            
            if fail_counter == 1:
                message_off = 0
                #print len(start_from_the_end), len(start_from_the_end[:-message_off])
                
                for i in range(0, len(start_from_the_end), n):
                    
                    if start_from_the_end[i:i+n] in HEX:
						message_off = i
						#print message_off
						break
                    else:
                        continue	
            
                count_per_two, fail = check_the_message(start_from_the_end[message_off:],m,n)
				
            
            if modified_check == "40":
                offset = 20
            else:
                offset = 0	

            #Let's clean up a bit.
            #Most of the times we have double quotation when a message was modified. 
            #Let's delete that character if it is at the beginning of the string
            if count_per_two[0] == '"':
				count_per_two = count_per_two[1:]
            
            #DEBUG CSV OPTION FOR CHATSYNC
            if DEBUG:
                csv = open(CSV_FILE, "a+")
                csv_temp = ""
            
            #Let's keep the message only if is different from the usernames. 
            #TODO these are not really messages. write algorithm to skip these messages from the beginning
            if count_per_two != self.user1 and count_per_two != self.user2:
                if DEBUG:
                    values = str(initial_length)+","+str(user_field_length)+","+str(u_debug_start)+","+str(u_header_2)+","+str(user)+","+str(footer)+","+str(next_timestamp)+","+str(timestamp)+"," +str(next_timestamp_check)+","+str(m_header)+","+str(get_hex)+","+str(bet_hex_and_date_open_tag)+","+str(bet_hex_and_date_value)+","+str(bet_hex_and_date_close_tag)+","+str(check_them)+ ","+str(modified_check)+ ","+str(len(count_per_two))+ ","+str(count_per_two)+ ","+str(count_per_two).encode("hex")+"\n"
                    
                   
                    
                    
                    debug_file.write(values)
                # MORE CSV DEBUG ON  
                fo = open(self.file_name, "r")
                l = fo.read()
                fo.seek(0x35,0)
                l = repr(fo.readline())
                l = l[1:l.find("\\x00\\x00\\x01")]
                l = "#"+l
              
                #csv_temp = user+"\t"+timestamp+"\t"+count_per_two+"\t"+l+"\n"
                #csv.write(csv_temp)
                # MORE CSV DEBUG OFF
                
                new_message = Message(self.user1, self.user2, self.chat_id, self.file_name, user, timestamp, count_per_two, status, get_hex  )
                self.messages.append(new_message)
            check_them = check_them-1
       
        if DEBUG:
            debug_file.close()
            debug_counter_finder.close()
       
        
		
    
        
    
class Message(object):
	
	# init
    def __init__(self, user1, user2, chat_id, file_name, user, timestamp, line, status, hex_check):
        self.user1 = user1
        self.user2 = user2
        self.chat_id = chat_id
        self.file_name = file_name
        self.user = user
        self.timestamp = timestamp
        self.line = line
        self.status = status
        self.hex_check = hex_check

        
	def __str__(self):
		chat_id = self.chat_id
		file_name = self.file_name 
		return chat_id, file_name
		
    	

def check_sync(file_in):
    path = file_in
    dirList=os.listdir(path)

    file_list = []

	#Get all the .dat files and their path:
    for root, subFolders, files in os.walk(path):
        path = root+"/"
		
        for element in files:
            if element != None:
                temp_list = []
                timestamp= os.path.getmtime(path+element)
                mod_time= datetime.datetime.fromtimestamp(timestamp).strftime("%Y%m%d%H%M%S")
		
                element = path+element
                size = os.path.getsize(element)
                #print str(element), str(element[-3:]), size
                now = date_me()
                if size == 0:
					print (now+": This file "+str(element)+" looks empty, file size: "+str(size)+"K. Not parsing...")
                elif str(element[-4:]) == ".dat":
                    temp_list.append(mod_time)
                    temp_list.append(element)
                    file_list.append(temp_list)
                    print (now+": "+str(element)+" file found, size: "+str(size)+"K.")
                else:
					print (now+": This file "+str(element)+" doesn't seem like a chatsync file. Not parsing...")    
    file_list.sort()
    #print file_list
    #print len(file_list)

	# Now Create a list for all the different chats between userA and userB, where
	# userA is the host skype user and userB is the remote host.
    i = 0
    chat_list = []
    user_list = []

    try:
        for chat_synch in file_list:
			
			
            fo = open(file_list[i][1], "r")
            line = fo.read()
            fo.seek(0x35,0)
            line = repr(fo.readline())
            line = line[:line.find("\\x00\\x00\\x01")]
            #size = os.path.getsize(file_list[i][1])

            #print (str(file_list[i][1])), size
            user1, user2 = line.split("/$")
            user1 = user1[1:]
            chat_list_temp = []
            if ";" in user2:
                user2, chat_id = user2.split(";",1)
            else:
                chat_id = user2
                user2 = "Group Chat"
            chat_list_temp.append(user1)
            chat_list_temp.append(user2)
            chat_list_temp.sort()
            chat_list_temp.append(chat_id)
            chat_list_temp.append(fo.name)
            chat_list.append(chat_list_temp)
            
            fo.close()
            i = i + 1
    except IndexError:
        print ("Fine Lista Baby")
       

    chat_list.sort()	
    
    conv = []    
    global last_user1, last_user2
    last_user1 = chat_list[0][0]
    last_user2 = chat_list[0][1]
    last_chat_id = chat_list[0][2]
    last_file_name = chat_list[0][3]
    #print last_user1, last_user2, last_chat_id, last_file_name	
    new_chat = Chat(last_user1, last_user2, last_chat_id, last_file_name)
    
    conv.append(new_chat)
	#print chat_list
    i = 1
    #print len(chat_list)    
    while i < len(chat_list):
        user1 = chat_list[i][0]
        user2 = chat_list[i][1]
        if len(chat_list[i]) != 3:
            if user1 == last_user1 and user2 == last_user2:
                new_chat = Chat(last_user1, last_user2, chat_list[i][2], chat_list[i][3])

            else:
                last_user1 = user1
                last_user2 = user2
                new_chat = Chat(last_user1, last_user2, chat_list[i][2], chat_list[i][3])	
                
            conv.append(new_chat)                
				
            i = i + 1
        elif len(chat_list[i]) == 3:
            if user1 == last_user1 and user2 == last_user2:
                
                conv.append(new_chat)
                new_chat = Chat(last_user1, last_user2, chat_list[i][1], chat_list[i][2])
                
            else:
                last_user1 = user1
                last_user2 = user2
                
                new_chat = Chat(last_user1, None, chat_list[i][1], chat_list[i][2])	
                
                conv.append(new_chat)
				
            i = i + 1        
    return conv


#check_sync()
if __name__ == "__main__":
	print("Your ran this module directly. you have to import it via skype.py")	
