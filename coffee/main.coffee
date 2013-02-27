$(document).ready ->
    $('#dial').cosmDial
        key: 'KqO5_LeJNPd2ReGJYVn_vfRf7QqSAKxPcE9jaVljSVJhMD0g'
        feedId: '58853'
        datastreamId: 'sensor1'
        min: 12
        max: 29
        decimal: true
        speed: 5000
    
    duration = '6hours'
    interval = 300
    
    $('#js-timespan-selector').val duration
    
    $('#js-timespan-selector').change ->
        duration = $(@).val()
        switch duration
            when '3hours' then interval = 60
            when '6hours' then interval = 300
            when '24hours' then interval = 900
        getHistory(duration, interval)
        subscribe(interval)
    
    stream = []
    
    plot = Morris.Line(
  
      # ID of the element in which to draw the chart.
      element: "wykres"
      
      # Chart data records -- each entry in this array corresponds to a point on
      # the chart.
      data: []
            
      # The name of the data record attribute that contains x-values.
      xkey: "timestamp"
      
      # A list of names of data record attributes that contain y-values.
      ykeys: ["value"]
      
      # Labels for the ykeys -- will be displayed when you hover over the
      # chart.
      labels: ['Temperatura']
      ymin: 'auto[15]'
      ymax: 'auto[21]'
      postUnits: '°C'
      lineColors: ['#444']
      pointSize: 0
      hideHover: 'auto'
      dateFormat: (x)->
        new Date(x).format('HH:MM')
    )
    offset = Math.abs(new Date().getTimezoneOffset()) * 60000
    cosm.setKey 'KqO5_LeJNPd2ReGJYVn_vfRf7QqSAKxPcE9jaVljSVJhMD0g'
    getData = ->
      cosm.datastream.get '58853', 'sensor1', (data) ->
        currentTime = new Date().getTime()
        stream.splice 0, 1
        stream.push
            timestamp: currentTime
            value: data.current_value
        plot.setData stream
        console.log 'graph updated, number of datapoints: ' + stream.length
    getHistory = (dur, int)->
        cosm.datastream.history '58853', 'sensor1',
            duration: dur
            interval: int
            per_page: 1000
            timezone: 'Warsaw'
        , (data) ->
            source = data.datapoints
            i = 0
            stream = []
            console.log 'creating graph with duration: ' + duration + ' and interval: ' + interval
            while i < source.length
              stream[i] =
                timestamp: Date.parse(source[i].at.slice(0, 19)) - offset
                value: source[i].value
              i++
            plot.setData stream
            console.log 'graph created, number of datapoints: ' + stream.length
          
    getHistory(duration, interval)
    
    subscribe = (int)->
        if sub?
            clearInterval(sub)
        sub = setInterval (->
            getData()
        ), int * 1000
        console.log 'graph will be refreshed every ' + (int * 1000)/60000 + ' minute(s)'
    
    subscribe(interval)
    
    