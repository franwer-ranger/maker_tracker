module ApplicationHelper
  MONTHS = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze

  # "12 sep"
  def short_date(time) = "#{time.day} #{MONTHS[time.month - 1]}"

  # "hoy", "ayer" o "3 oct"; con `time: true`, "ayer 22:40" (hoy: "hoy 09:12").
  def relative_day(time, time_of_day: false)
    day = if time.to_date == Date.current then "hoy"
    elsif time.to_date == Date.yesterday then "ayer"
    else short_date(time)
    end
    time_of_day && time.to_date >= Date.yesterday ? "#{day} #{time.strftime('%H:%M')}" : day
  end
end
