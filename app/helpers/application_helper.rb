# ## ApplicationHelper
#
# View helpers for the weather UI. Each method receives domain value objects
# (from +Services::Domains::Weather+) and returns safe HTML or plain strings
# suitable for ERB templates.
#
# ### Public methods
#
# - {#weather_condition_icon_tag} — +<img>+ for the condition icon, or a text +<span>+ fallback.
# - {#weather_hourly_label} — Display label for an hourly forecast column ("Now", "14:00", …).
# - {#weather_temp_bar_style} — Inline CSS +left/right+ for a temperature range bar.
# - {#weather_source_badge} — Tiny "API" / "Cache" indicator with a coloured dot.
module ApplicationHelper
  # Renders a weather condition icon as an +<img>+ tag, falling back to a
  # text +<span>+ when no icon URI is available.
  #
  # @param weather_condition [Domains::Weather::WeatherCondition]
  # @param size [Integer] pixel width and height (default 24)
  # @param css_class [String] additional CSS classes for the +<img>+
  # @return [ActiveSupport::SafeBuffer]
  def weather_condition_icon_tag(weather_condition, size: 24, css_class: "")
    url = weather_condition_icon_url(weather_condition)
    return tag.span(weather_condition.description, class: "text-zinc-500 text-xs") unless url

    tag.img(
      src: url,
      alt: weather_condition.description,
      width: size,
      height: size,
      loading: :lazy,
      class: "inline-block #{css_class}".strip
    )
  end

  # Returns a short time label for one column in the hourly forecast grid.
  #
  # - Index 0 always returns <tt>"Now"</tt>.
  # - Otherwise extracts the time portion (after the space) from
  #   +entry.display_date_time+ (e.g. <tt>"2025-06-15 14:00"</tt> → <tt>"14:00"</tt>).
  # - Returns <tt>"--"</tt> when the timestamp is blank.
  #
  # @param entry [Domains::Weather::HourlyForecastEntry]
  # @param index [Integer] zero-based position in the forecast array
  # @return [String]
  def weather_hourly_label(entry, index)
    return "Now" if index == 0
    return "--" if entry.display_date_time.blank?

    parts = entry.display_date_time.to_s.split(" ")
    parts.size > 1 ? parts.last : parts.first
  end

  # Computes inline CSS for positioning a temperature range bar within a
  # global min/max scale. The returned string sets +left+ and +right+
  # percentages so the bar spans only the day's range.
  #
  # Returns <tt>"left: 0%; right: 0%;"</tt> when the global range is zero
  # (all days share the same temperature).
  #
  # @param min_temp [Numeric] day's low temperature
  # @param max_temp [Numeric] day's high temperature
  # @param global_min [Numeric] lowest temperature across all forecast days
  # @param global_max [Numeric] highest temperature across all forecast days
  # @return [String] inline CSS style string
  def weather_temp_bar_style(min_temp, max_temp, global_min, global_max)
    range = global_max - global_min
    return "left: 0%; right: 0%;" if range <= 0

    left  = ((min_temp - global_min) / range * 100).round
    right = ((global_max - max_temp) / range * 100).round
    "left: #{left}%; right: #{right}%;"
  end

  # Renders a small badge showing whether data for +key+ came from the
  # live API (green dot + "API") or from cache (grey dot + "Cache").
  #
  # @param result [Services::Application::WeatherByAddress::Result]
  # @param key [Symbol] one of +:geocode+, +:current_weather+,
  #   +:hourly_forecast+, or +:daily_forecast+
  # @return [ActiveSupport::SafeBuffer]
  def weather_source_badge(result, key)
    cached = result.from_cache?(key)
    dot_class = cached ? "bg-zinc-500" : "bg-emerald-500/80 shadow-[0_0_6px_rgba(16,185,129,0.4)]"
    label = cached ? "Cache" : "API"

    tag.span(class: "flex items-center gap-1.5 text-[10px] font-normal text-zinc-500") do
      tag.span(class: "w-1 h-1 rounded-full #{dot_class}") + label
    end
  end

  private

  # Appends +.png+ to the condition's icon base URI, or returns +nil+
  # when no URI is set.
  def weather_condition_icon_url(weather_condition)
    return nil if weather_condition.icon_base_uri.blank?

    "#{weather_condition.icon_base_uri}.png"
  end
end
