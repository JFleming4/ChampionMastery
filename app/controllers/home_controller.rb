require 'net/http'
require 'json'
require 'pp'
# Controller for the stats page
class HomeController < ApplicationController
  helper_method :build_grid_view
  def home
    @options = {}
    @grid = []
    person = params['person']
    @mastery = MasteryInfo.new(person['sumName'], person['region'])
    champion_level_values = []
    @img_string = "http://ddragon.leagueoflegends.com/cdn/#{@mastery.champions.fetch(:version)}/img/champion/"
    # @next_champ_level = process_next_champ_level
    # @mystery_chest = process_mystery_chest

    @mastery.champion_level.each do |_, val|
      champion_level_values.push(val.length)
    end
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
    options={responsive: true}
  end

  def build_grid_view
    params['sort'] = params['sort'].presence || 'Alpha'
    params['filter_type'] = params['filter_type'].presence || 'All'
    params['size'] = params['size'].presence || '6'
    list = sort_list(sort, filter_type)
    list.each_slice(size.to_i).to_a
  end

  def sort_list(sort, filter_type)
    list = @mastery.champions_grid if filter_type == 'All'
    list = @mastery.champion_chest if filter_type == 'Chest'
    list = @mastery.champion_no_chest if filter_type == 'NoChest'
    list = list.sort { |a, b| a.fetch(:name).upcase <=> b.fetch(:name).upcase } if sort == 'Alpha'
    list = list.sort { |a, b| b.fetch(:points) <=> a.fetch(:points) } if sort == 'Most'
    list = list.sort { |a, b| a.fetch(:nxLvl) <=> b.fetch(:nxLvl) } if sort == 'Level'
    list
  end

  # def process_next_champ_level
  #   champions = @mastery.champions.fetch(:data)
  #   next_level_return = []
  #   next_level = @mastery.next_level
  #   next_level.each do |champ_obj|
  #     champ = champions.fetch(champ_obj.fetch(:champId).to_s.to_sym)
  #     next_level_return.push(
  #       img: "#{@img_string}#{champ.fetch(:image).fetch(:full)}",
  #       title: "#{champ.fetch(:name)}: #{champ_obj.fetch(:points)}"
  #     )
  #   end
  #   next_level_return
  # end

  # def process_mystery_chest
  #   champions = @mastery.champions.fetch(:data)
  #   mystery_return = []
  #   mystery = @mastery.champion_chest
  #   mystery.each do |champ_id|
  #     champ = champions.fetch(champ_id.to_s.to_sym)
  #     mystery_return.push(
  #       img: "#{@img_string}#{champ.fetch(:image).fetch(:full)}",
  #       title: "#{champ.fetch(:name)}"
  #     )
  #   end
  #   mystery_return
  # end

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

    def champion_list
      uri = URI("#{@champion_url}")
      params = { dataById: true, champData: 'image' }
      query(uri, params)
    end

    def query(uri, params = {})
      uri.query = URI.encode_www_form(params.merge(api_key: @api))
      response = Net::HTTP.get_response(uri)
      pie = JSON.parse(response.body, symbolize_names: true)
      pie
    end
  end

  # Return the relevant info for the champion mastery of a given summoner
  class MasteryInfo
    attr_reader :champion_level, :champions, :champion_chest, :champions_grid, :champion_no_chest
    def api_key
      api_file_path = File.join(Dir.home, '.riot', 'credentials')
      File.read(api_file_path).chomp
      # ENV['api_key']
    end

    def process_mastery
      @champion_mastery.each do |champion_data|
        champion_id = champion_data.fetch(:championId)
        @champion_level[champion_data.fetch(:championLevel).to_s.to_sym]
          .push(champion_id)
        champion = {
          champId: champion_id,
          name: champions.fetch(:data).fetch(champion_id.to_s.to_sym).fetch(:name),
          nxLvl: champion_data.fetch(:championPointsUntilNextLevel),
          points: champion_data.fetch(:championPoints),
          chest: champion_data.fetch(:chestGranted),
          img: "http://ddragon.leagueoflegends.com/cdn/#{champions.fetch(:version)}/img/champion/#{champions.fetch(:data).fetch(champion_id.to_s.to_sym).fetch(:image).fetch(:full)}"
        }
        if champion_data.fetch(:chestGranted)
          @champion_chest.push(champion)
        else
          @champion_no_chest.push(champion)
        end
        @champions_grid.push(champion)
      end
    end

    def initialize(name, region = 'na')
      @champion_chest = []
      @champion_no_chest = []
      @champions_grid = []
      @champion_level = { '7': [], '6': [], '5': [], '4': [], '3': [], '2': [], '1': [] }
      @summmoner_name = name
      @riot = API.new(api_key, @summmoner_name, region)
      @summoner_id = @riot.get_summoner_id_byname(@summmoner_name)
      @champion_mastery = @riot.get_champion_mastery(@summoner_id)
      @champions = @riot.champion_list
      process_mastery
      # @next_level = @next_level.sort { |a, b| a.fetch(:points).to_f <=> b.fetch(:points).to_f }
    end
  end
end
