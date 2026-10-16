module ApplicationHelper
  MONTHS = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze

  # "a, b y c" (to_sentence usa el inglés por defecto).
  def y_sentence(items) = items.to_sentence(words_connector: ", ", two_words_connector: " y ", last_word_connector: " y ")

  # "12 sep"
  def short_date(time) = "#{time.day} #{MONTHS[time.month - 1]}"

  # "hace 5 min", "hace 2 h", "ayer", "hace 3 días".
  def ago_in_words(time)
    seconds = Time.current - time
    if seconds < 1.hour then "hace #{[ (seconds / 60).floor, 1 ].max} min"
    elsif seconds < 1.day then "hace #{(seconds / 1.hour).floor} h"
    elsif time.to_date == Date.yesterday then "ayer"
    else "hace #{(Date.current - time.to_date).to_i} días"
    end
  end

  # "hoy", "ayer" o "3 oct"; con `time: true`, "ayer 22:40" (hoy: "hoy 09:12").
  def relative_day(time, time_of_day: false)
    day = if time.to_date == Date.current then "hoy"
    elsif time.to_date == Date.yesterday then "ayer"
    else short_date(time)
    end
    time_of_day && time.to_date >= Date.yesterday ? "#{day} #{time.strftime('%H:%M')}" : day
  end
end
