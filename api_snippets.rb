class API < Sinatra::Base

end

app = API.new(ledger: Ledger.new)