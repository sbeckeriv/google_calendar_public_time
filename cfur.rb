module CFur
  def self.days_ago(days)
    now=Time.now
    Time.now-days*24*60*60
  end
  def self.get_cal_list(access_token)
    response=nil
    count=0
    url = "https://www.googleapis.com/calendar/v3/users/me/calendarList?pp=1&key="+ENV["GKEY"]
    begin
      count+=1
      response = access_token.get(url)
      if response.is_a?(Net::HTTPRedirection)
        url = URI.parse(response['location'].to_s).to_s
      end
    end while (!response.is_a?(Net::HTTPSuccess) && count < 5)
    
    if(response.is_a?(Net::HTTPSuccess))
      b=response.body
      cal = JSON.parse(response.body)
    else
      cal = nil
    end
  end
end
