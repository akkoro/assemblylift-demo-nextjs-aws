require 'asml'
require 'json'

def http_request(input)
    return invoke("akkoro.std.http.request", input)
end

def get_secret_value(input)
    return invoke("akkoro.aws.secretsmanager.get_secret_value", input)
end

# IOmod input and output is always JSON
def invoke(coords, input)
    return JSON.parse(wait_for_io(Asml.iomod_invoke(coords, JSON.generate(input))))
end

# Async support in WebAssemby Ruby is still in-progress
# For now we spin-loop until we receive a response, essentially blocking on each IOmod call
def wait_for_io(ioid)
    loop do
        res = Asml.get_io_document(ioid)
        return res if res != nil
    end
end
