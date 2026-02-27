module ApplicationHelper
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

  def weather_hourly_label(entry, index)
    return "Now" if index == 0
    return "--" if entry.display_date_time.blank?

    parts = entry.display_date_time.to_s.split(" ")
    parts.size > 1 ? parts.last : parts.first
  end

  def weather_temp_bar_style(min_temp, max_temp, global_min, global_max)
    range = global_max - global_min
    return "left: 0%; right: 0%;" if range <= 0

    left  = ((min_temp - global_min) / range * 100).round
    right = ((global_max - max_temp) / range * 100).round
    "left: #{left}%; right: #{right}%;"
  end

  def weather_source_badge(result, key)
    cached = result.from_cache?(key)
    dot_class = cached ? "bg-zinc-500" : "bg-emerald-500/80 shadow-[0_0_6px_rgba(16,185,129,0.4)]"
    label = cached ? "Cache" : "API"

    tag.span(class: "flex items-center gap-1.5 text-[10px] font-normal text-zinc-500") do
      tag.span(class: "w-1 h-1 rounded-full #{dot_class}") + label
    end
  end

  private

  def weather_condition_icon_url(weather_condition)
    return nil if weather_condition.icon_base_uri.blank?

    "#{weather_condition.icon_base_uri}.png"
  end
end
