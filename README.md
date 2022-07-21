# Bank Parsing Test

Welcome to Jenfi's bank parsing test 2!

Now that you're familiar with our basic parsing concepts we want to expand on these ideas.

## Goal

We've added 2 new data files (they're very similar for this test) that are a different format.

Our goal is to understand how you might approach different formats.

Please make the specs pass again.

## How does this work?

This time, you can modify any file you need to achieve a good solution.

## Key Files

- `lib/bank_parser.rb`
- `spec/lib/bank_parser_spec.rb`
- `spec/fixtures/*.(yml|xml|html)`
  - `.xml` is raw data that can come from an ePDF or API.
  - `.html` helpful to visualize the data.
    - `$ open spec/fixtures/banking_data_1.html`
    - `$ open spec/fixtures/banking_data_2.html`
    - `$ open spec/fixtures/banking_data_3.html`
    - `$ open spec/fixtures/banking_data_4.html`
  - `.yml` is sucessfully parsed/extracted data that we can ultimately use to insert into a database.
- `ExtractorHelper` module
  - LOTS of extra code.
  - Shows examples of how more complex extractions can happen.

## Start Instructions

1. Ensure `ruby -v` is `~3.1`
1. `bundle install`
1. `bundle exec rspec .`

## Helpful Info

- **Do NOT**
  - Simply hardcode the output. Our goal is to understand your ability to learn a new process.
  - Try to build an API, Database.
