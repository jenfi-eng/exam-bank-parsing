class BankParser
  include ExtractorHelpers

  # Example: 30-Jun-2020
  DATE_FORMAT = '%d-%b-%Y'

  def parse(raw_xml)
    output = {}
    noko = Nokogiri::XML(raw_xml)

    # Key Parsing for this Test
    output[:account_info_raw] = account_info(noko)

    # Other parsing - see ExtractorHelpers
    output[:dates_covered] = doc_dates(noko)
    output[:transaction_rows_raw] = transaction_rows(nil, noko)

    [output]
  end

  def account_info(noko)
    account_name = ''
    account_id = ''
    currency = ''

    {
      account_name: account_name,
      account_id: account_id,
      currency: currency,
    }
  end
end