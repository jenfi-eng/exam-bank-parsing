Money.default_currency = Money::Currency.new("SGD")
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
Money.locale_backend = :i18n