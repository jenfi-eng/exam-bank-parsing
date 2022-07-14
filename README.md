# Bank Parsing Test

Welcome to Jenfi's bank parsing test!

The goal is to expose you to actual processes and code of a key aspect of our company in less than 4 hours.

**PLEASE** DON'T FORGET TO ANSWER THE QUESTIONS BELOW

## Goal

Make the test pass by modifying `BankParser#account_info`.

From the nokogiri, please extract:

- Account Name
- Account Number
- Currency

The **only** function you need to modify is `account_info`. No other files need modification.

## How does this work?

The test simply compares the output of `BankParser#parse` to what is stored in the `.yml` file and expects them to match.

## Key Files

- `lib/bank_parser.rb`
  - The **only** file you need to modify.
- `spec/fixtures/*.(yml|xml|html)`
  - `.xml` is raw data that can come from an ePDF or API.
  - `.html` helpful to visualize the data.
    - `$ open spec/fixtures/banking_data_1.html`
    - `$ open spec/fixtures/banking_data_2.html`
  - `.yml` is sucessfully parsed/extracted data that we can ultimately use to insert into a database.
- `ExtractorHelper` module
  - LOTS of extra code.
  - Shows examples of how more complex extractions can happen.

## Start Instructions

1. Ensure `ruby -v` is `~3.1`
1. `bundle install`
1. `bundle exec rspec .`

## Questions to Answer

1. From your solution, what do you believe could be improved in your code AND Jenfi's?
1. How do you ensure data integrity or how do you keep 'dirty data' out of the system?

## Helpful Info

- **Do NOT**
  - Simply hardcode the output. Our goal is to understand your ability to learn a new process.
  - Try to build an API, Database or extend it any fashion.
- Quickly learn Nokogiri.
