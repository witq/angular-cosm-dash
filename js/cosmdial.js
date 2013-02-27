(function($) {
	$.fn.cosmDial = function(options) {
		return this.each(function() {
		
			// Domyślne ustawienia
			
			var settings = $.extend({
				feedId: '58853',
				datastreamId: 'sensor1',
				key: 'KqO5_LeJNPd2ReGJYVn_vfRf7QqSAKxPcE9jaVljSVJhMD0g',
				min: 15,
				max: 33,
				color: 'undefined',
				unit: 'undefined',
				speed: 1000,
				decimal: true
			}, options);
			
			// Przycisk "ustawienia" itd. - do dopracowania
			
			$(this).addClass('cosmDial').append($('<div class="reading">').append('<span class="value">').append('<br>').append('<span class="unit">')).append($('<div class="min">').text(settings.min)).append($('<div class="max">').text(settings.max));
			$(this).after(('<button class="btn btn-warning flipper"><i class="icon-wrench icon-white"></i> Ustawienia</button>'));
			$(this).parent().find('.flipper').click(function() {
				$(this).parent().parent().parent().addClass('flip');
			});
			$(this).parent().parent().parent().find('.flopper').click(function() {
				$(this).parent().parent().parent().removeClass('flip');
			});
			
			// Zmienne
			
			var container = $(this),
				elementId = container.attr('id'),
				valueContainer = container.find('.value'),
				unitContainer = container.find('.unit'),
				width = container.width(),
				fontScale = width / 20,
				arcColor = '',
				currentValue = settings.min,
				dial = Raphael(elementId, width, width);
			if (settings.color === 'undefined') {
				var arcStartColor = "#0000ff";
			} else {
				var arcStartColor = settings.color;
			}
			container.css('font-size', fontScale);
			
			// Funkcja kreśląca łuk
			
			dial.customAttributes.arc = function(xloc, yloc, value, total, R) {
				var alpha = 360 / total * value,
					a = (90 - alpha) * Math.PI / 180,
					x = xloc + R * Math.cos(a),
					y = yloc - R * Math.sin(a),
					path;
				if (total === value) {
					path = [
						["M", xloc, yloc - R],
						["A", R, R, 0, 1, 1, xloc - 0.01, yloc - R]
					];
				} else {
					path = [
						["M", xloc, yloc - R],
						["A", R, R, 0, +(alpha > 180), 1, x, y]
					];
				}
				return {
					path: path
				};
			};
			
			// Tło wskaźników
			
			var dialBackground = dial.path().attr({
				"stroke": "#fff",
				"stroke-linecap": "round",
				"stroke-width": 0.01 * width,
				arc: [width / 2, width / 2, 270, 360, 0.45 * width]
			}).transform("r-135," + width / 2 + "," + width / 2);
			
			// Wskaźnik
			
			var dialArc = dial.path().attr({
				"stroke": arcStartColor,
				"stroke-linecap": "round",
				"stroke-width": 0.1 * width,
				arc: [width / 2, width / 2, 0, 360, 0.45 * width]
			}).transform("r-135," + width / 2 + "," + width / 2);
			
			// Rysowanie wskaźnika

			function drawArc(data, quick) {
				var arcSpan = reScale(data.current_value, [settings.min, settings.max], [0, 270]);
				if (arcSpan > 270) {
					arcSpan = 270;
				}
				if (arcSpan < 0) {
					arcSpan = 0;
				}
				if (settings.color === 'undefined') {
					var arcHue = reScale(data.current_value, [settings.min, settings.max], [240, 0]);
					if (arcHue < 0) {
						arcHue = 0;
					}
					if (arcHue > 240) {
						arcHue = 240;
					}
					arcColor = Raphael.hsl(arcHue, 85, 60);
				} else {
					arcColor = settings.color;
				}
				if (quick == true) {
					dialArc.animate({
						"stroke": arcColor,
						arc: [width / 2, width / 2, arcSpan, 360, 0.45 * width]
					}, 100);
				} else {
					dialArc.animate({
						"stroke": arcColor,
						arc: [width / 2, width / 2, arcSpan, 360, 0.45 * width]
					}, settings.speed, "<>");
				}
			}
			
			// Funkcja wyświetlania wartości strumienia z przejściem przez pośrednie wartości przy zmianie
			
			function setValue(data, easing) {
			
				// http://www.bennadel.com/blog/2007-Using-jQuery-s-animate-Method-To-Power-Easing-Based-Iteration.htm?&_=0.15331789385527372&_=0.17502885544672608#comments_41207
				
			    var easer = $("<div>");
			    var stepIndex = 0;
			    var estimatedSteps = Math.ceil(settings.speed / 13);
			
			    easer.css("opacity", currentValue);
			    easer.animate({
			        opacity: data.current_value
			    }, {
			        easing: easing,
			        duration: settings.speed,
			        step: function(index) {
			            set(index);
			        }
			    });
			    currentValue = data.current_value;
			};
			
			// Ustawianie jednostki

			function setUnit(data) {
				if (typeof data.unit !== 'undefined') {
					if (data.unit.symbol !== 'undefined') {
						if (settings.unit !== 'undefined') {
							unitContainer.text(settings.unit);
						} else {
							unitContainer.text(data.unit.symbol);
						}
					}
				} else {
					if (settings.unit !== 'undefined') {
						unitContainer.text(settings.unit);
					}
				}
			}
			
			// Wyznaczanie bezwzględnej różnicy między dwiema wartościami

			function difference(a, b) {
				return Math.abs(a - b);
			}
			
			// Funkcja skalowania

			function reScale(value, srcScale, dstScale) {
				return Math.round(((value - srcScale[0]) / (srcScale[1] - srcScale[0])) * (dstScale[1] - dstScale[0]) + dstScale[0]);
			}
			
			// Funkcja ustawiania wartości
			
			function set(i) {
				i = Math.round(i * 10) / 10;
				if (settings.decimal == true) {
					i = i.toFixed(1);
				} else {
					i = i.toFixed(0);
				}
				valueContainer.text(i);
			}

			// Ustawienie klucza API
			
			cosm.setKey(settings.key);
			
			// Początkowe pobranie wartości
			
			cosm.datastream.get(settings.feedId, settings.datastreamId, function(data) {
				console.log('init of ' + settings.datastreamId + ' with value: ' + data.current_value);
				setUnit(data);
				drawArc(data);
				setValue(data, "easeInOutQuad");
			});
			
			// Uruchomienie subskrybcji nowych wartości w czasie rzeczywistym (z opóźnieniem równym ustawionej szybkości zmiany)
			
			setTimeout(function(){
				cosm.datastream.subscribe(settings.feedId, settings.datastreamId, function(event, data) {
					console.log('update of ' + settings.datastreamId + ' with new value: ' + data.current_value);
					drawArc(data);
					setValue(data, "easeInOutQuad");
				});
			},settings.speed);
				
			// Przerysowanie wskaźników i przeskalowanie czcionek w przypadku zmiany rozmiarów kontenera
			
			container.resize(function() {
				width = container.width();
				fontScale = width / 20;
				container.css('font-size', fontScale);
				dial.clear();
				dial.setSize(width, width);
				dialBackground = dial.path().attr({
					"stroke": "#fff",
					"stroke-linecap": "round",
					"stroke-width": 0.01 * width,
					arc: [width / 2, width / 2, 270, 360, 0.45 * width]
				}).transform("r-135," + width / 2 + "," + width / 2);
				dialArc = dial.path().attr({
					"stroke": arcStartColor,
					"stroke-linecap": "round",
					"stroke-width": 0.1 * width,
					arc: [width / 2, width / 2, 0, 360, 0.45 * width]
				}).transform("r-135," + width / 2 + "," + width / 2);
				cosm.datastream.get(settings.feedId, settings.datastreamId, function(data) {
					drawArc(data, true);
					setValue(data, "easeInOutQuad");
				});
			});
		});
	};
})(jQuery);