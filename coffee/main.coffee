$ = jQuery
    
$.fn.extend
    cosmDial: (options) ->
        # Domyślne ustawienia
        settings =
            feedId: '58853'
            datastreamId: 'sensor1'
            key: 'KqO5_LeJNPd2ReGJYVn_vfRf7QqSAKxPcE9jaVljSVJhMD0g'
            min: 15
            max: 33
            color: 'undefined'
            unit: 'undefined'
            speed: 1000
            decimal: true
        
        $.extend settings, options
        
        
        return @each () ->
            
            container = $(this)
            
            class Dial
                constructor: (data, settings) ->
                    @data = data
                    @settings = settings
                
                # Zmienne
                
                @elementId = container.attr('id')
                @valueContainer = container.find('.value')
                @unitContainer = container.find('.unit')
                @width = container.width()
                @fontScale = width / 20
                @currentValue = settings.min
                
                # Metody wewnętrzne 
                
                # Wyznaczanie bezwzględnej różnicy między dwiema wartościami
                @difference: (a, b) ->
                    Math.abs(a - b)
                
                # Inicjalizacja
                setup: ->
                    # Pola tekstowe
                    container.addClass('cosmDial').append($('<div class="reading">').append('<span class="value">').append('<br>').append('<span class="unit">')).append($('<div class="min">').text(settings.min)).append($('<div class="max">').text(settings.max))
            
            
            wskaznik = new Dial
            wskaznik.setup()
            
            # Zmienne
            elementId = container.attr('id')
            valueContainer = container.find('.value')
            unitContainer = container.find('.unit')
            width = container.width()
            fontScale = width / 20
            currentValue = settings.min
            dial = Raphael(elementId, width, width)
            
            container.css 'font-size', fontScale
            
            if settings.color is 'undefined'
                arcStartColor = '#0000ff'
            else
                arcStartColor = settings.color
                
            # Funkcja kreśląca łuk
            dial.customAttributes.arc = (xloc, yloc, value, total, R) ->
                alpha = 360 / total * value
                a = (90 - alpha) * Math.PI / 180
                x = xloc + R * Math.cos(a)
                y = yloc - R * Math.sin(a)
                if total is value
                    path = [["M", xloc, yloc - R], ["A", R, R, 0, 1, 1, xloc - 0.01, yloc - R]]
                else
                    path = [["M", xloc, yloc - R], ["A", R, R, 0, +(alpha > 180), 1, x, y]]
                path:
                    path
            
            # Tło wskaźników
            dialBackground = dial.path().attr(
                'stroke': '#fff',
                'stroke-linecap': 'round',
                'stroke-width': 0.1 * width,
                arc: [width / 2, width / 2, 270, 360, 0.45 * width]
            ).transform('r-135,' + width / 2 + ',' + width / 2)
            
            # Wskaźnik
            dialArc = dial.path().attr(
                'stroke': arcStartColor
                'stroke-linecap': 'round'
                'stroke-width': 0.1 * width
                arc: [width / 2, width / 2, 0, 360, 0.45 * width]
            ).transform('r-135,' + width / 2 + ',' + width / 2)
            
            # Rysowanie wskaźnika
            drawArc = (data) ->
                arcSpan = reScale(data.current_value, [settings.min, settings.max], [0, 270])
                arcSpan = 270 if arcSpan > 270
                arcSpan = 0 if arcSpan < 0
                if settings.color is 'undefined'
                    arcHue = reScale(data.current_value, [settings.min, settings.max], [240, 0])
                    arcHue = 240 if arcHue > 240
                    arcHue = 0 if arcHue < 0
                    arcColor = Raphael.hsl(arcHue, 85, 60)
                else
                    arcColor = settings.color
                dialArc.animate
                    stroke: arcColor
                    arc: [width / 2, width / 2, arcSpan, 360, 0.45 * width]
                , settings.speed, '<>'
                
            # Funkcja wyświetlania wartości
            setValue = (data, easing) ->
                easer = $('<div>')
                setpIndex = 0
                estimatedSteps = Math.ceil(settings.speed/13)
                
                easer.css 'opacity', currentValue
                easer.animate
                    opacity: data.current_value
                ,
                    easing: easing
                    duration: settings.speed
                    step: (index) ->
                        set index
                currentValue = data.current_value
            
            # Ustawianie jednostki
            setUnit = (data) ->
                if typeof data.unit isnt 'undefined'
                    if settings.unit isnt 'undefined'
                        unitContainer.text settings.unit
                    else
                        unitContainer.text data.unit.symbol
                else
                    if settings.unit isnt 'undefined'
                        unitContainer.text settings.unit
            
            # Wyznaczanie bezwzględnej różnicy między dwiema wartościami
            difference = (a, b) ->
                Math.abs(a - b)
            
            # Funkcja skalowania
            reScale = (value, srcScale, dstScale) ->
                Math.round(((value - srcScale[0]) / (srcScale[1] - srcScale[0])) * (dstScale[1] - dstScale[0]) + dstScale[0])
                
            # Funkcja ustawiania wartości
            set = (i) ->
                i = Math.round(i * 10) / 10
                if settings.decimal is true
                    i = i.toFixed(1)
                else
                    i = i.toFixed(0)
                valueContainer.text i
                
            
            # Ustawienie klucza API Cosm
            cosm.setKey settings.key
            
            # Początkowe pobranie wartości
            cosm.datastream.get settings.feedId, settings.datastreamId, (data) ->
                console.log 'init of ' + settings.datastreamId + ' with value: ' + data.current_value
                setUnit data
                drawArc data
                setValue data, 'easeInOutQuad'
            
            # Uruchomienie subskrypcji nowych wartości
            setTimeout (->
                cosm.datastream.subscribe settings.feedId, settings.datastreamId, (event, data) ->
                    console.log 'update of ' + settings.datastreamId + ' with value: ' + data.current_value
                    drawArc data
                    setValue data, 'easeInOutQuad'
            ), settings.speed


$(document).ready ->
    $('#dial').cosmDial
        key: 'KqO5_LeJNPd2ReGJYVn_vfRf7QqSAKxPcE9jaVljSVJhMD0g'
        feedId: '58853'
        datastreamId: 'sensor1'
        min: 12
        max: 29
        decimal: true
        speed: 5000
    
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
    cosm.datastream.history '58853', 'sensor1',
      duration: '6hours'
      interval: 300
      per_page: 1000
      timezone: 'Warsaw'
    , (data) ->
      source = data.datapoints
      i = 0
      while i < source.length
        stream[i] =
          timestamp: Date.parse(source[i].at.slice(0, 19)) - offset
          value: source[i].value
        i++
      console.log 'graph created, number of datapoints: ' + stream.length
      plot.setData stream
    
    setInterval (->
      getData()
    ), 300000