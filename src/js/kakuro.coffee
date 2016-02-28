$ ->

  loadKakuro('kakuros/2016-01-08.txt')

  # kakuroRactive = new Ractive
  #   el: '#kakuro-container'
  #   template: '#kakuro-template'
  #   data:
  #     poop: 'test1'
  #     shoop: 'test2'

loadKakuro = (url) ->
  $.get(url, (data) ->
    new Kakuro(data)
  )



class Kakuro
  constructor: (text) ->
    @cells = []
    for line in text.split('\n')
      row = []
      for cell in line.split(',')
        row.push(cell)
      @cells.push(row)
    @cells.pop()
    console.log(@cells)

class Cell
  constructor: (text) ->
    @raw = text

  type: ->
    if @raw == 'x'
      return 'BLANK'
    if @raw.includes('-')
      return 'TOTAL'
    return 'NUMBER'

  render: ->
    if @type() == 'BLANK'
      return '<td class="blank"></td>'
    if @type() == 'TOTAL'
      return '<td class="total">' +
        '<table>' +
          '<tr>' + '<td>' + @topRight() + '</td>' + '</tr>' +
          '<tr>' + '<td>' + @bottomLeft() + '</td>' + '</tr>' +
        '</table>' +
      '</td>'
    return '<td class="number">' + @number() + '</td>'

  topRight: ->
    @raw.split('-')[1]

  bottomLeft: ->
    @raw.split('-')[0]

  number: ->
    @raw
