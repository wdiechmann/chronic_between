#!/usr/bin/env ruby

# file: chronic_between.rb

require 'chronic'
require 'date'
require 'app-routes'

class ChronicBetween

  def initialize(s)
    @s = s
  end
  
  def within?(date)
    
    params = {};  @date_ranges = []    
    @app = AppRoutes.new(params)
    
    set_ranges(params, date)
    @s.split(',').each {|x| @app.run(x.strip)}
    @date_ranges.any? {|d1, d2| date.between? d1, d2}
  end  
  
  private
  
  def set_ranges(params, date)

    @app.routes do

      # e.g. Mon-Fri 9:00-16:30
      get %r{(\w+)-(\w+)\s+(\d+:\d+)-(\d+:\d+)$} do 
        
        d1, d2, t1, t2 = params[:captures]
        cdate1, cdate2 = [d1,d2].map {|d| Chronic.parse(d)}
        n_days = (cdate2 - cdate1) / 86400
        
        0.upto(n_days.to_i).each do |n|          
          x = (cdate1.to_date + n).strftime("%d-%b-%y ")
          @date_ranges << [DateTime.parse(x + t1), DateTime.parse(x + t2)]
        end        

      end

      # e.g. Saturday
      get %r{^(\w+)$} do
        day = params[:captures].first
        cdate = Chronic.parse(day, :now => (date - 1))
        d1 = DateTime.parse(cdate.strftime("%d-%b-%y") + ' 00:00')
        d2 = d1 + 1
        @date_ranges << [d1, d2]
      end

      # e.g. 3:45-5:15
      get %r{^(\d+:\d+)-(\d+:\d+)$} do
        t1, t2 = params[:captures]        
        @date_ranges << [t1,t2].map {|t| DateTime.parse(t)}
      end

      # e.g. Mon 3:45-5:15
      get %r{^(\w+)\s+(\d+:\d+)-(\d+:\d+)$} do                                                    
        d, t1, t2 = params[:captures]        
        x = Chronic.parse(d, :now => (date - 1)).strftime("%d-%b-%y ")
        @date_ranges << [DateTime.parse(x + t1), DateTime.parse(x + t2)]
      end

      # e.g. Mon-Wed
      get %r{^(\w+)-(\w+)$} do                                                    
        d1, d2 = params[:captures]        
        cdate1, cdate2 = [d1,d2].map {|d| Chronic.parse(d)}
        n_days = (cdate2 - cdate1) / 86400
        
        date = DateTime.parse(cdate1.strftime("%d-%b-%y") + ' 00:00')
        @date_ranges << [date, date + n_days.to_i]
      end

    end

  end
  
  def get(arg,&block)
    @app.get(arg, &block)
  end      

end
