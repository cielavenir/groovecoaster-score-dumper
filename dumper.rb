#!/usr/bin/ruby
#coding:utf-8
#GrooveCoaster Score Dumper
#(C) @cielavenir under Fair License.

raise 'Ruby 1.9+ required' if RUBY_VERSION<'1.9'

require 'mechanize'
require 'json'
load 'conf.rb'

output=File.open('scores.'+(CSV ? 'csv' : 'txt'),'w',CSV ? {encoding:'Windows-31J'} : {})

mech=Mechanize.new
mech.user_agent="Mozilla/5.0"
#login
mech.get('https://mypage.groovecoaster.jp/')
mech.page.forms[0].field_with({name:'nesicaCardId'}).value=NESiCA
mech.page.forms[0].field_with({name:'password'}).value=Password
mech.page.forms[0].submit
if mech.page.forms.size>0
	puts 'login failed. please check conf.rb.'
end
sleep(1)

#music list
mech.get('https://mypage.groovecoaster.jp/sp/json/music_list.php',[],'https://mypage.groovecoaster.jp/sp/')
music_list=JSON.parse(mech.page.body)['music_list']
sleep(1)
if CSV
	output.puts 'Music,Simple,Normal,Hard,Extra,'
end

#iterate music
music_list.each_with_index{|music,i|
	mech.get('https://mypage.groovecoaster.jp/sp/json/music_detail.php?music_id='+music['music_id'].to_s,[],'https://mypage.groovecoaster.jp/sp/')
	score=JSON.parse(mech.page.body)['music_detail']
	if CSV
		output.print '"'+score['music_title'].tr('〜','～').gsub('"','""')+'",'
	else
		output.puts score['music_title']
		#output.puts score['artist'] ### artist is required for database ###
	end
	['simple','normal','hard','extra'].each{|difficulty|
		if CSV
			if result=score[difficulty+'_result_data']
				output.print "#{result['score']},"
			else
				output.print ','
			end
		else
			output.print difficulty+":\t"
			if result=score[difficulty+'_result_data']
				output.puts "#{result['score']}(#{result['rating']})\tMaxChain:#{result['max_chain']}\tAdlib:#{result['adlib']}\tプレイ回数:#{result['play_count']}回\tNoMiss:#{result['no_miss']}回\tFullChain:#{result['full_chain']}回"
			else
				output.puts 'N/A'
			end
		end
	}
	output.puts
	STDERR.print "Dumped "+(i+1).to_s+"\r"
	sleep(1)
}
STDERR.puts

output.close
