require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'OpenSSL'

class Player
	attr_accessor :name, :score, :value, :position

	def initialize(name,position)
		@name = name
		@position = position
	end
end

$url_base = "http://games.espn.go.com/ffl/tools/projections?slotCategoryId="
def parse_names
	names=[]

	path = "//td[@class='playertablePlayerName']"
	$page1.xpath(path).each do |node|
		cell = node.text.split(/\W/)
		cell.delete_if {|x| x.empty?}

		name = "#{cell[0]} #{cell[1]}"
		names << name

	end
	return names
end

def parse_projections
	scores=[]
	path = "//td[@class='playertableStat appliedPoints']"
	$page1.xpath(path).each do |node|
		cell = node.text
		scores << cell
	end
	scores.shift
	return scores
end

def get_data(position)
	category_id = {"QB"=>"0", "RB"=>"2", "WR"=>"4", "TE"=>"6", "D"=>"16", "K"=>"17"}
		url = $url_base + category_id[position.upcase]
		$page1 = Nokogiri::HTML(open(url))
		names = parse_names
		scores = parse_projections
		players = create_players(names,scores,position)
		players = get_values(players)
	return players
end

def create_players(names,scores,position)
	players = []
	names.each_with_index do |name|
		player = Player.new(name, position)	
		players << player
	end
	scores.each_with_index {|projection, index| players[index].score = projection.to_f}
	return players
end

def find_top_players_avg(players)
	players.sort! {|a,b| b.score<=>a.score}
	total = 0
	0.upto(19) do |i|
		total += players[i].score
	end
	avg = total/20
	return avg
end

def find_top_players_median(players)
	players[9].score + players[10].score / 2
end

def get_values(players)
	top_avg = find_top_players_avg(players)
	top_median = find_top_players_median(players)
	top_low = players[19].score
	weight = top_median / top_avg
	players.map do |player|
		player.value = (player.score - top_low) * weight
	end
	return players
end

def find_low_players_avg(players)
	total = 0
	20.upto(39) do |i|
		total += players[i].score
	end
	avg = total/20
	return avg
end

def find_low_players_median
	players[29].score + players[30].score / 2
end

qb = get_data("qb")
rb = get_data("rb")
wr = get_data("wr")
te = get_data("te")
d = get_data("d")
k = get_data("k")

players = qb + rb + wr + te + d + k
players.sort!{|a,b| b.value <=>a.value}

puts "Ready"

what_do = gets.chomp
until what_do == "quit"
case what_do

when "top"
	0.upto(19) do |i|
		puts "#{i+1}. #{players[i].name}, #{players[i].position.upcase}   #{players[i].value.round(3)}"
	end

when "20"
	20.upto(39) do |i|
		puts "#{i+1}. #{players[i].name}, #{players[i].position.upcase}   #{players[i].value.round(3)}"
	end

when "40"
	40.upto(59) do |i|
		puts "#{i+1}. #{players[i].name}, #{players[i].position.upcase}   #{players[i].value.round(3)}"
	end

when "60"
	60.upto(79) do |i|
		puts "#{i+1}. #{players[i].name}, #{players[i].position.upcase}   #{players[i].value.round(3)}"
	end

when "qb"
	qb.each_with_index {|player, i| puts "#{i}. #{player.name}, #{player.position}   #{player.value.round(3)}"}

when "rb"
	rb.each_with_index {|player, i| puts "#{i}. #{player.name}, #{player.position}   #{player.value.round(3)}"}

when "wr"
	wr.each_with_index {|player, i| puts "#{i}. #{player.name}, #{player.position}   #{player.value.round(3)}"}

when "te"
	te.each_with_index {|player, i| puts "#{i}. #{player.name}, #{player.position}   #{player.value.round(3)}"}

when "d"
	d.each_with_index {|player, i| puts "#{i}. #{player.name}, #{player.position}   #{player.value.round(3)}"}
when "k"
	k.each_with_index {|player, i| puts "#{i}. #{player.name}, #{player.position}   #{player.value.round(3)}"}
else
	puts "Try again"
end
what_do = gets.chomp

end