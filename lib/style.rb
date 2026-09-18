# frozen_string_literal: true

# Minimal ANSI presentation helpers shared by every demo.
# Pure Ruby: escape codes, box-drawing glyphs, and puts. No gems.
module Style
  module_function

  def bold(text) = wrap("1", text)
  def dim(text) = wrap("2", text)
  def gold(text) = fg("220", text)
  def azure(text) = fg("75", text)
  def violet(text) = fg("141", text)
  def sage(text) = fg("114", text)
  def coral(text) = fg("210", text)
  def gray(text) = fg("245", text)

  def fg(code, text) = "\e[38;5;#{code}m#{text}\e[0m"
  def wrap(code, text) = "\e[#{code}m#{text}\e[0m"

  # ── section header: ── title · subtitle ──────────────
  def banner(title, subtitle = nil)
    puts
    puts azure("──── ") + bold(violet(title)) + (subtitle ? gray("  ·  #{subtitle}") : "")
  end

  # one trace line inside a demo
  def step(text)
    puts "   #{gray('·')} #{text}"
  end

  # dim remark indented under a step
  def note(text)
    puts "       #{dim(text)}"
  end

  def ok(text)
    puts "   #{sage('✓')} #{text}"
  end

  def miss(text)
    puts "   #{coral('✗')} #{text}"
  end

  # human-readable lexicographic score: overload first, then imbalance
  def score(assignments)
    overload, imbalance = Problem.score(assignments).map { |v| -v }
    overload_label = overload.positive? ? coral("overload #{overload}") : sage("overload #{overload}")
    "#{overload_label} #{gray('·')} #{dim("imbalance #{imbalance}")}"
  end

  # scalar energy for the metaheuristics: 100 * overload + imbalance (minimize)
  def energy(assignments)
    e = Problem.energy(assignments)
    e >= 100 ? coral("energy #{e}") : sage("energy #{e}")
  end

  def energy_value(e)
    e >= 100 ? coral(e.to_s) : e <= 10 ? sage(e.to_s) : gold(e.to_s)
  end

  # one search iteration:  it 3 · t2(2) m0→m1    104 → 101 · accepted (better)
  def iteration(n, move_desc, from_e, to_e, verdict)
    arrow = to_e < from_e ? sage("→") : to_e == from_e ? gold("→") : coral("→")
    pair = "#{energy_value(from_e)} #{arrow} #{energy_value(to_e)}"
    puts "   #{gray(format('it %-2d', n))} #{bold(format('%-16s', move_desc))} #{pair}   #{dim(verdict)}"
  end

  # m1[9]  ▕██████░░░░▏ 6/9
  def gauge(label, used, capacity, width: 12)
    over = used > capacity
    ratio = capacity.positive? ? used.to_f / capacity : 1.0
    filled = (ratio * width).ceil.clamp(0, width)
    body = "█" * filled + "░" * (width - filled)
    color = over ? "210" : ratio > 0.85 ? "220" : "114"
    suffix = over ? coral(" #{used}/#{capacity} +#{used - capacity} over") : dim(" #{used}/#{capacity}")
    puts "   #{format('%-8s', label)} #{fg(color, body)}#{suffix}"
  end

  # 0 ⇢ 1 ⇢ 3 ⇢ 0   cost 12
  def route_line(route)
    stops = [fg("245", "0")] + route.map { |s| azure(s.to_s) } + [fg("245", "0")]
    puts "   #{stops.join(violet(' ⇢ '))}   #{gray('cost')} #{bold(Problem.route_cost(route))}"
  end
end
