require 'net/http'
require 'json'
require 'pp'
class HomeController < ApplicationController
  def home
    @options = {}
    person = params['person']
    mastery = MasteryInfo.new(person['sumName'], person['region'])
    champion_grade_values = []
    champion_level_values = []
    mastery.champion_rank.each do |_, val|
      champion_grade_values.push(val.length)
    end

    mastery.champion_level.each do |_, val|
      champion_level_values.push(val.length)
    end
    @data_grade = {
      labels: ['S+', 'S', 'S-', 'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-'],
      datasets: [
        label: 'Highest Champion Grade',
        fillColor: 'rgba(151,187,205,0.2)',
        strokeColor: 'rgba(151,187,205,1)',
        pointColor: 'rgba(151,187,205,1)',
        pointStrokeColor: '#fff',
        pointHighlightFill: '#fff',
        pointHighlightStroke: 'rgba(151,187,205,1)',
        data: champion_grade_values
      ]
    }
    @data_level = {
      labels: ['7', '6', '5', '4', '3', '2', '1'],
      datasets: [
        label: 'Highest Champion Grade',
        fillColor: 'rgba(151,187,205,0.2)',
        strokeColor: 'rgba(151,187,205,1)',
        pointColor: 'rgba(151,187,205,1)',
        pointStrokeColor: '#fff',
        pointHighlightFill: '#fff',
        pointHighlightStroke: 'rgba(151,187,205,1)',
        data: champion_level_values
      ]
    }
  end

  # Manage API calls for an entered user
  class API
    def initialize(api_key, name, region = 'na')
      @api = api_key
      @region = region
      @platform_id = get_platform_id(@region)
      @champion_url = 'https://global.api.pvp.net/api/lol/static-data/na/v1.2/champion'
      @baseurl = "https://#{@region}.api.pvp.net"
      @static_data_url = "#{@baseurl}/api/lol/static-data/#{@region}/v1.2"
      @summoner_data_url = "#{@baseurl}/api/lol/#{@region}/v1.4/summoner"
      @summoner_id = get_summoner_id_byname(name)
      @champioin_mastery_url = "#{@baseurl}/championmastery/location/#{@platform_id}/player"
    end

    def get_platform_id(region)
      case region
      when 'na' then 'NA1'
      when 'eune' then 'EUN1'
      when 'euw' then 'EUW1'
      when 'jp' then 'JP1'
      when 'kr' then 'KR'
      when 'lan' then 'LA1'
      when 'las' then 'LA2'
      when 'oce' then 'OC1'
      when 'ru' then 'RU'
      when 'tr' then 'TR1'
      else ''
      end
    end

    def get_champion_mastery(summoner_id)
      uri = URI("#{@champioin_mastery_url}/#{summoner_id}/champions")
      query(uri)
    end

    def get_summoner_id_byname(name_sum)
      name = name_sum.chomp.delete(' ').downcase
      summoner = summoner_byname(name)
      summoner.fetch(name.to_sym).fetch(:id)
    end

    def summoner_byname(name)
      path_val = URI.encode_www_form_component(name)
      uri = URI("#{@summoner_data_url}/by-name/#{path_val}")
      query(uri)
    end

    def get_champion_list
    end

    def query(uri)
      uri.query = URI.encode_www_form(api_key: @api)
      response = Net::HTTP.get_response(uri)
      pie = JSON.parse(response.body, symbolize_names: true)
      pie
    end
  end

  # Return the relevant info for the champion mastery of a given summoner
  class MasteryInfo
    attr_reader :champion_rank
    attr_reader :champion_level
    def api_key
      # api_file_path = File.join(Dir.home, '.riot', 'credentials')
      # File.read(api_file_path).chomp
      ENV['api_key']
    end

    def process_mastery
      @champion_mastery.each do |champion_data|
        champion_id = champion_data.fetch(:championId)
        process_highest_grade(champion_data, champion_id)
        @champion_level[champion_data.fetch(:championLevel).to_s.to_sym]
          .push(champion_id)
        @champion_chest.push(champion_id) if champion_data.fetch(:chestGranted)
        process_next_level(champion_data, champion_id)
      end
    end

    def process_next_level(champion, champ_id)
      return if champion[:championPointsUntilNextLevel].nil?
      return unless champion.fetch(:championPointsUntilNextLevel) < 200
      @next_level.push(champ_id)
    end

    def process_highest_grade(champion, champ_id)
      return if champion[:highestGrade].nil?
      @champion_rank[champion.fetch(:highestGrade).to_sym].push(champ_id)
    end

    def initialize(name, region = 'na')
      @champion_chest = []
      @next_level = []
      @champion_rank = {
        'S+': [],
        'S': [],
        'S-': [],
        'A+': [],
        'A': [],
        'A-': [],
        'B+': [],
        'B': [],
        'B-': [],
        'C+': [],
        'C': [],
        'C-': [],
        'D+': [],
        'D': [],
        'D-': []
      }
      @champion_level = {
        '7': [],
        '6': [],
        '5': [],
        '4': [],
        '3': [],
        '2': [],
        '1': []
      }
      @summmoner_name = name
      @riot = API.new(api_key, @summmoner_name, region)
      @summoner_id = @riot.get_summoner_id_byname(@summmoner_name)
      @champion_mastery = @riot.get_champion_mastery(@summoner_id)
      process_mastery
    end
  end
end
