require 'json'
require 'aws-sdk-ssm'

def root
  "blog"
end

def get_counter(client, issue_id)
  res = client.get_parameter({
    name: "/#{root}/#{issue_id}",
    with_decryption: false,
  })
  return { issue_id: issue_id, star: res.parameter['value'].to_i }
end

def update_counter(client, issue_id, count)
  res = client.put_parameter({
   name: "/#{root}/#{issue_id}",
   value: count,
   type: "String",
   overwrite: true
  })
end

def count_up(client, issue_id)
  begin
    count = get_counter(client, issue_id)[:star]
  rescue Aws::SSM::Errors::ParameterNotFound
    count = 0
  ensure
    count = count + 1
    update_counter(client, issue_id, count.to_s)
    return { issue_id: issue_id, star: count.to_i }
  end
end

def list_counters(client)
  res = client.get_parameters_by_path({
    path: "/#{root}"
  })
end

def delete_counter(client, issue_id)
  delete = client.delete_parameter({
   name: "/#{root}/#{issue_id}"
  })
end

def lambda_handler(event:, context:)
    
  client = Aws::SSM::Client.new()
  issue_id = event.dig("pathParameters", "issue_id")
  http_method = event.dig("requestContext", "http", "method")
    
  begin
    case http_method
      when "PUT"
        count_up(client, issue_id)
      when "GET"
        get_counter(client, issue_id)
      when "LIST"
        list_counters(client)
      when "DELETE"
        delete_counter(client, issue_id)
      else 0 
    end
  rescue => e
    { statusCode: 500, body: e.to_json }
  end
    
end


=begin

curl -X GET -H "Content-Type: application/json" https://**********.execute-api.ap-northeast-1.amazonaws.com/1234/star 
curl -X DELETE -H "Content-Type: application/json" https://**********.execute-api.ap-northeast-1.amazonaws.com/1234/star
curl -X PUT -H "Content-Type: application/json" https://**********.execute-api.ap-northeast-1.amazonaws.com/1234/star 
curl -X LIST -H "Content-Type: application/json" https://**********.execute-api.ap-northeast-1.amazonaws.com/1234/star 

=end
