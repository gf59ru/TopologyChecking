require 'net/http'
require 'json'

class TopologyController < ApplicationController

  def initialize
    @server = 'http://qwerty-3:6080/arcgis/rest/services'
    @service_folder = 'Training'
    @service_name = 'CheckTopology'
    @gp_server = 'GPServer/CheckTopology'
    @gdb_name = '%D0%9D%D0%B0%D0%B8%D0%BC%D0%B5%D0%BD%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5_%D0%B1%D0%B0%D0%B7%D1%8B'
    @class_set_name = '%D0%9D%D0%B0%D0%B8%D0%BC%D0%B5%D0%BD%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5_%D0%BD%D0%B0%D0%B1%D0%BE%D1%80%D0%B0_%D0%BA%D0%BB%D0%B0%D1%81%D1%81%D0%BE%D0%B2'
    @class_name = '%D0%98%D0%BC%D1%8F_%D0%BA%D0%BB%D0%B0%D1%81%D1%81%D0%B0_%D0%BF%D1%80%D0%BE%D1%81%D1%82%D1%80%D0%B0%D0%BD%D1%81%D1%82%D0%B2%D0%B5%D0%BD%D0%BD%D1%8B%D1%85_%D0%BE%D0%B1%D1%8A%D0%B5%D0%BA%D1%82%D0%BE%D0%B2'
    @topology_name = '%D0%9D%D0%B0%D0%B8%D0%BC%D0%B5%D0%BD%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5_%D1%82%D0%BE%D0%BF%D0%BE%D0%BB%D0%BE%D0%B3%D0%B8%D0%B8'
  end

  def check
    uri = URI "#{@server}/#{@service_folder}/#{@service_name}/#{@gp_server}/submitJob?#{@gdb_name}=GDB&#{@class_set_name}=class_set&#{@class_name}=class1&#{@topology_name}=Topology&env%3AoutSR=&env%3AprocessSR=&returnZ=false&returnM=false&f=json"
    Net::HTTP.start uri.host, uri.port do |http|
      request = Net::HTTP::Get.new uri.request_uri
      response = http.request request
      json = JSON.parse response.body
      job_uri = URI "#{@server}/#{@service_folder}/#{@service_name}/#{@gp_server}/jobs/#{json['jobId']}?f=pjson"
      # job_uri = URI response.header['location']
      Net::HTTP.start job_uri.host, job_uri.port do |job_http|
        job_request = Net::HTTP::Get.new job_uri.request_uri
        job_response = job_http.request job_request
        json = JSON.parse job_response.body
        puts json
      end
    end
  end

end
