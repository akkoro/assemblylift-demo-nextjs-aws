require 'asml'
require 'base64'
require 'json'

require_relative 'io'

def main(input)
    # Fetch our secret containing our Xata slug and API key
    secret = get_secret_value({
        SecretId: 'arn:aws:secretsmanager:us-east-1:235724345984:secret:demos/nextjs/xata-osxcK4'
    })
    secret = JSON.parse(secret["Ok"]["SecretString"])

    ip = input['pathParameters']['ip']
    res = query_counter(ip, secret)
    body = JSON.parse(res["Ok"]["body"])
    records = body["records"]
    
    # FIXME Xata supports UPSERT but I haven't had time to rewrite this yet :)
    if records.length > 0
        id = records[0]["id"]
        count = records[0]["count"] + 1
        update_count(id, count, secret)
    else
        insert_count(ip, secret)
    end

    Asml.success(JSON.generate("{}"))
end

def query_counter(ip, secret)
    return http_request({
        method: 'POST',
        host: "#{secret['workspace_slug']}.xata.sh",
        path: '/db/nextjs-demo:main/tables/counter/query',
        headers: {
            Authorization: "Bearer #{secret['key']}"
        },
        content_type: 'application/json',
        body: JSON.generate({
            filter: {
                ip: ip
            }
        })
    })
end

def insert_count(ip, secret)
    return http_request({
        method: 'POST',
        host: "#{secret['workspace_slug']}.xata.sh",
        path: '/db/nextjs-demo:main/tables/counter/data',
        headers: {
            Authorization: "Bearer " + secret['key']
        },
        content_type: 'application/json',
        body: JSON.generate({
            ip: ip,
            count: 1,
        })
    })
end

def update_count(id, count, secret)
    return http_request({
        method: 'PATCH',
        host: "#{secret['workspace_slug']}.xata.sh",
        path: '/db/nextjs-demo:main/tables/counter/data/' + id,
        headers: {
            Authorization: "Bearer " + secret['key']
        },
        content_type: 'application/json',
        body: JSON.generate({
            count: count,
        })
    })
end

# Because this is a script, we need to invoke main() ourselves
main(JSON.parse(Asml.get_function_input()))
