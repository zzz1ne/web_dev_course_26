#lab2
require 'date'

class CalendarBuilder
  DAYS_MAP = { 5 => 'Пт', 6 => 'Сб', 0 => 'Вс' }
  GAME_TIMES = [12, 15, 18]
  MAX_GAMES_PER_SLOT = 2

  def initialize(args)
    validate_args_count(args)
    @teams_file = args[0]
    @start_date = parse_date(args[1])
    @end_date = parse_date(args[2])
    @output_file = args[3]
    
    validate_dates
    @teams = read_teams
    validate_teams
  end

  def build
    matches = generate_matches
    slots = generate_available_slots
    
    if matches.count > slots.count
      raise "Недостаточно игровых слотов для проведения всех матчей (Нужно: #{matches.count}, Доступно: #{slots.count})"
    end

    schedule = distribute_matches(matches, slots)
    write_calendar(schedule)
    
    puts "Календарь успешно создан: #{@output_file}"
    puts "Всего команд: #{@teams.count}"
    puts "Всего матчей: #{matches.count}"
    puts "Период: #{@start_date} - #{@end_date}"
  end

  private
  def validate_args_count(args)
    raise "Ошибка: Ожидалось 4 аргумента (файл команд, дата начала, дата конца, файл вывода). Получено: #{args.count}" unless args.count == 4
  end

  def parse_date(str)
    begin
      Date.strptime(str, '%d.%m.%Y')
    rescue ArgumentError
      raise "Ошибка: Неверный формат даты '#{str}'. Ожидался ДД.ММ.ГГГГ"
    end
  end

  def validate_dates
    raise "Ошибка: Дата начала должна быть раньше даты конца" if @start_date > @end_date
  end

  def read_teams
    raise "Ошибка: Файл команд #{@teams_file} не найден" unless File.exist?(@teams_file)
    teams = []
    File.foreach(@teams_file, encoding: 'UTF-8') do |line|
      line = line.strip
      next if line.empty?

      clean_line = line.sub(/^\d+\.\s*/, '')
      
      parts = clean_line.split(' — ')
      if parts.count != 2
        raise "Ошибка в файле команд: Строка '#{line}' не содержит разделитель ' — '"
      end
      
      teams << { name: parts[0].strip, city: parts[1].strip } #
    end
    
    teams
  end

  def validate_teams
    raise "Ошибка: Для турнира нужно минимум 2 команды. Найдено: #{@teams.count}" if @teams.count < 2
  end

  def generate_matches
    matches = []
    (0...@teams.count).each do |i|
      ((i + 1)...@teams.count).each do |j|
        matches << { home: @teams[i], away: @teams[j] }
      end
    end
    matches
  end

  def generate_available_slots
    slots = []
    current = @start_date
    
    while current <= @end_date
      if DAYS_MAP.key?(current.wday)
        GAME_TIMES.each do |hour|
          MAX_GAMES_PER_SLOT.times do
            slots << DateTime.new(current.year, current.month, current.day, hour, 0, 0)
          end
        end
      end
      current += 1
    end
    
    slots
  end

  def distribute_matches(matches, slots)
    schedule = []
    total_slots = slots.count
    total_matches = matches.count
    step = total_slots.to_f / total_matches
    
    matches.each_with_index do |match, index|
      slot_index = (index * step).round
      slot_index = total_slots - 1 if slot_index >= total_slots
      
      schedule << {
        datetime: slots[slot_index],
        home: match[:home],
        away: match[:away]
      }
    end
    schedule.sort_by { |item| item[:datetime] }
  end

  #Вывод 
  def write_calendar(schedule)
    File.open(@output_file, 'w', encoding: 'UTF-8') do |f|
      f.puts " СПОРТИВНЫЙ КАЛЕНДАРЬ "
      f.puts
      current_date = nil     
      schedule.each do |game|
        game_date = game[:datetime].to_date
        game_time = game[:datetime].strftime('%H:%M')
        day_name = DAYS_MAP[game_date.wday]
        if current_date != game_date
          f.puts "#{game_date.strftime('%d.%m.%Y')} (#{day_name})"
          current_date = game_date
        end
        home_str = "#{game[:home][:name]} (#{game[:home][:city]})"
        away_str = "#{game[:away][:name]} (#{game[:away][:city]})"
        
        f.puts "  #{game_time}  |  #{home_str}  vs  #{away_str}"
      end
      
      f.puts
      f.puts " Конец календаря "
    end
  end
end

begin
  builder = CalendarBuilder.new(ARGV)
  builder.build
rescue => e
  puts "ОШИБКА: #{e.message}"
  exit 1
end