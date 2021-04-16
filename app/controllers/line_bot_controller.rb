class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end
    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.message['text'].include?("今日の料理")
            message = create_message
          else
            message = {
              type: 'text',
              text: event.message['text'] = "「今日の料理は?」と入力してね！"
            }
          end
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end

  private
 
    def client
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end

    def create_message
      http_client = HTTPClient.new
      url = 'https://app.rakuten.co.jp/services/api/Recipe/CategoryRanking/20170426'
      query = {
         'applicationId' => ENV['RAKUTEN_APPID'],
         'categoryId' => '10',
         'formatVersion' => 2,
         'elements' => "recipeTitle,recipeUrl,foodImageUrl,recipeIndication"
       }
       response = http_client.get(url, query)
       response = JSON.parse(response.body)

      
      text = "こんなのいかがでしょう！" +"\n" + "\n" + "" 
      response["result"].each do |recipe|
        text << 
       recipe["recipeTitle"] + "\n" +
       recipe["recipeUrl"] + "\n" +
      #  recipe["foodImageUrl"] + "\n" +
        "目安時間:" + recipe["recipeIndication"] + "\n" +
       "\n"
      end
      
      message = {
         type: 'text',
         text: text
       }
      
    end
end
