# frozen_string_literal: true

module ExtractorHelpers
  include ActionView::Helpers::NumberHelper

  DOT_DELIMITER_REGEX = /^\d{1,3}(.\d{3})*(,\d+)?$/ # format: 10.123.456,00
  COMMA_DELIMITER_REGEX = /^\d{1,3}(,\d{3})*(.\d+)?$/ # format: 10.123.456,00

  MONEY_REGEX = /^[+-]?[0-9]{1,3}(?:[0-9]*(?:[.,][0-9]{2})?|(?:,[0-9]{3})*(?:\.[0-9]{2})?|(?:\.[0-9]{3})*(?:,[0-9]{2})?)$/
  DELIMETER_REGEX = /[.,]/
  DATE_REGEX = %r{^(0?[1-9]|[12][0-9]|3[01])[/\-](0?[1-9]|1[012])[/\-](\d{4}|\d{2})$} # %d-%m-%Y or %d/%m/%Y or %d/%m/%y
  MISSING_YEAR_DATE_REGEX = /^\d{2}-\d{2}-/ # %d-%m-%Y

  def br_to_newline(noko)
    return if noko.blank?

    dup_noko = noko.dup
    dup_noko.css('br').each { |br| br.replace "\n" }
    dup_noko.text
  end

  def split_by_br(noko)
    text = br_to_newline(noko)
    text.split("\n")
  end

  def santize_money_text(text)
    return '' unless text.match(MONEY_REGEX)

    text
  end

  def extract_trxn_text(output, noko, tds, current_bal_text)
    prev_balance_text = doc_or_row_balance_text(output, noko)
    trxn_amount_text = trxn_amount_text_finder(tds)
    trxn_classifier(prev_balance_text, trxn_amount_text, current_bal_text)
  end

  def doc_or_row_balance_text(output, noko)
    if output.count.zero?
      return @doc_opening_bal if @doc_opening_bal.present?

      opening_bal_text = doc_opening_bal(noko)
      return unless opening_bal_text

      @doc_opening_bal = opening_bal_text if opening_bal_text.match?(MONEY_REGEX)
    else
      output.last[:balance]
    end
  end

  def doc_opening_bal(_noko)
    raise NotImplementedError
  end

  # start_looking_from_right - Normally balance col is at -1, so we normally start at -2.
  def trxn_amount_text_finder(tds, search_max_cols: 4, search_offset_from_right: 2)
    (search_offset_from_right..(search_offset_from_right + search_max_cols)).each do |pos|
      text = tds[tds.length - pos].text

      return text if text&.match?(MONEY_REGEX)
    end
    nil
  end

  def trxn_classifier(opening_balance_text, trxn_amount_text, current_row_balance_text)
    opening_balance = Monetize.parse(opening_balance_text)
    trxn_amount = Monetize.parse(trxn_amount_text)
    row_balance = Monetize.parse(current_row_balance_text)

    trxn_amount = trxn_amount.abs if trxn_amount.negative?

    if opening_balance + trxn_amount == row_balance
      deposit_text = trxn_amount.to_s
    elsif opening_balance - trxn_amount == row_balance
      withdraw_text = trxn_amount.to_s
    end

    {
      withdraw: withdraw_text,
      deposit: deposit_text,
    }
  end

  def simple_row_math_checks_out?(rows)
    rows.each_with_index do |row, index|
      next if index.zero?

      prev_bal = Monetize.parse(rows[index - 1][:balance])
      row_bal = Monetize.parse(row[:balance])
      row_dep = Monetize.parse(row[:deposit])
      row_wit = Monetize.parse(row[:withdraw])

      return false if prev_bal != row_bal - row_dep + row_wit
    end

    true
  end

  # Date Pattern: 02-Sep-2019
  def doc_dates(noko)
    opening_date = doc_opening_date(noko)
    closing_date = doc_closing_date(noko)

    [[opening_date, closing_date]]
  rescue Date::Error
    nil
  end

  def math_checks_out?(noko, rows)
    document_withdraw = Monetize.parse(
      noko.xpath(
        '//tr/td[starts-with(text(), "Total Debit Count :")]/..'
      ).text.match(/Total Debit Count :.*Total Debit Amount :\s?(.*)/)[1]
    )
    document_deposit = Monetize.parse(
      noko.xpath(
        '//tr/td[starts-with(text(), "Total Credit Count :")]/..'
      ).text.match(/Total Credit Count :.*Total Credit Amount :\s?(.*)/)[1]
    )

    extracted_withdraw = extracted_deposit = Money.new(0.0)
    rows.each do |row|
      extracted_withdraw += Monetize.parse(row[:withdraw])
      extracted_deposit += Monetize.parse(row[:deposit])
    end

    return true if
      simple_row_math_checks_out?(rows) &&
      document_withdraw == extracted_withdraw &&
      document_deposit == extracted_deposit

    false
  end

  def transaction_rows(_account_info, noko)
    output = []

    # rubocop:disable Metrics/BlockLength
    noko.xpath('//page').each do |page|
      next if page.text.match?(/No Data Found For Selected Criteria/)

      page.xpath('*/tr/td[.="Value Date"]/parent::tr/following-sibling::tr').each do |tr|
        break if tr.text.match?(/(Printed By :|Total Debit Count :)/)

        tds = tr.children

        balance_text = tds[tds.length - 1].text

        if balance_text.present?
          begin
            Date.parse(tds[0].text)
            Date.parse(tds[1].text)
          rescue ArgumentError
            if (tds[0].text.blank? && tds[1].text.present?) ||
                (tds[0].text.present? && tds[1].text.match?(MONEY_REGEX))

              output = special_row_handling(output, noko, tds)
            end

            next
          end

          next unless extract_date(tds, noko)

          trxn_text = extract_trxn_text(output, noko, tds, balance_text)

          # Using tds.length-offset-x because sometimes description has extra cols
          output << {
            date: extract_date(tds, noko),
            details: br_to_newline(tds[2]),
            balance: balance_text,
          }.merge(trxn_text)
        else
          output[output.length - 1][:details] = "#{output[output.length - 1][:details]}\n#{tds[2].text}"
        end
      end
    end

    output
  end

  private

  # Nightmare scenario
  # <tr>
  #   <td colspan="2">11-Sep-2019</td><td style="text-align: right" colspan="4">201.80</td>
  # </tr>
  # <tr>
  #   <td></td><td>11-Sep-2019</td><td>CHEQUE</td><td></td><td style="text-align: right" colspan="2">31,483.17</td>
  # </tr>
  def special_row_handling(output, _noko, tds)
    if tds[0].text.present?
      output << {
        date: Date.parse(tds[0].text),
        withdraw_deposit_text: santize_money_text(tds[-1].text),
      }
    elsif tds[1].text.present?
      # Now that we have the actual balance
      prev_bal_text = output[output.length - 2][:balance]
      trxn_amount_text = output[output.length - 1][:withdraw_deposit_text]
      balance_text = tds[-1].text

      output[output.length - 1] = output[output.length - 1].merge(
        trxn_classifier(prev_bal_text, trxn_amount_text, balance_text)
      )

      output[output.length - 1][:details] = "#{output[output.length - 1][:details]}\n#{tds[2].text}"
    else
      raise 'Both cells were empty, why?'
    end

    output[output.length - 1][:balance] = balance_text

    output
  end

  # This function is a nightmare
  # Sometimes the DBS running balance column has 2 td's in it...WTF
  def dbs_left_wrap_offset(page)
    # Find the header rows
    page.search('tr').each do |tr|
      # This TR is the header rows
      next unless tr.children.text.match(/Running Balance/)
      next unless tr.children.count == 6 &&
                  tr.children.last.attributes.keys.include?('colspan') &&
                  tr.children.last.attributes['colspan'].value == '2'

      return 1
    end

    0
  end

  def extract_date(tds, noko)
    date_1 = Date.parse(tds[0].text)
    date_2 = Date.parse(tds[1].text)

    begin
      opening_date = doc_opening_date(noko)

      closing_date = doc_closing_date(noko)
    rescue Date::Error
      return false
    end

    # Check if both dates are outrageous
    if ((date_1 < opening_date - 2.weeks) && (date_2 < opening_date - 2.weeks)) ||
        ((date_1 > closing_date + 2.weeks) && (date_2 > closing_date + 2.weeks))
      raise "Dates for document are way out of range: #{date_1} #{date_2}"
    end

    if date_1 == date_2
      date_1
    elsif date_1 > date_2
      date_1
    else
      date_2
    end
  end

  def doc_opening_bal(noko)
    opening_bal_text = noko.xpath(
      '//tr/td[starts-with(., "Opening Balance :")]/following-sibling::td[1]'
    ).text

    return opening_bal_text if opening_bal_text.match?(MONEY_REGEX)

    text_arr = noko.xpath(
      '//tr/td[starts-with(., "Opening Balance :")]/following-sibling::td[1]'
    ).text.split

    return if text_arr.count <= 1

    text_arr[0] if text_arr[0].match?(MONEY_REGEX)
  end

  def doc_opening_date(noko)
    return @doc_opening_date if @doc_opening_date.present?

    opening_date_text = noko.xpath(
      '//tr/td[starts-with(., "Opening Balance :")]/following-sibling::td[2]'
    ).text

    begin
      @doc_opening_date = Date.strptime(opening_date_text, self.class::DATE_FORMAT)
    rescue Date::Error
      text_arr = noko.xpath(
        '//tr/td[starts-with(., "Opening Balance :")]/following-sibling::td[1]'
      ).text.split

      return if text_arr.count <= 1

      @doc_opening_date = Date.strptime(text_arr[1], self.class::DATE_FORMAT)
    end

    @doc_opening_date
  end

  def doc_closing_date(noko)
    return @doc_closing_date if @doc_closing_date.present?

    closing_date_text = noko.xpath(
      '//tr/td[starts-with(., "Ledger Balance :")]/following-sibling::td[2]'
    ).text

    begin
      @doc_closing_date = Date.strptime(closing_date_text, self.class::DATE_FORMAT)
    rescue Date::Error
      text_arr = noko.xpath(
        '//tr/td[starts-with(., "Ledger Balance :")]/following-sibling::td[1]'
      ).text.split

      return if text_arr.count <= 1

      @doc_closing_date = Date.strptime(text_arr[1], self.class::DATE_FORMAT)
    end

    @doc_closing_date
  end
end
