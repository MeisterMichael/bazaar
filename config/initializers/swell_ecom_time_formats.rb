Time::DATE_FORMATS[:basic_short] = lambda { |time| time.strftime("%B %d, %Y") }
Time::DATE_FORMATS[:basic_shorter] = lambda { |time| time.strftime("%b %d, %Y") }
