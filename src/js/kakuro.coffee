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
    k = new Kakuro(data)
    # k.clear()
    $('#kakuro-container').html(k.toHtml())
  )

powersum = () ->
  return window.ps if window.ps?

  sums = ([] for x in [0..45])
  l = [1..9]
  max = 1 << l.length
  for bitmask in [1...max]
    cur = []
    for j in [0..l.length]
      if ((bitmask & (1 << j)) > 0)
        cur.push(l[j])
    total = cur.reduce (x,y) -> x+y
    sums[total].push(cur)
  window.ps = sums
  sums

ways = (total, length) ->
  powersum()[total].filter((x) -> x.length == length)

toBitmask = (arr) ->
  mask = 0
  for i in arr
    mask |= (1 << i-1)
  mask

toArray = (bitmask) ->
  arr = []
  for j in [1..9]
    if ((bitmask & (1 << j-1)) > 0)
      arr.push(j)
  arr

intersect = (arr1, arr2) ->
  toArray(toBitmask(arr1) & toBitmask(arr2))


class Kakuro
  constructor: (text) ->
    @cells = []
    for line, y in text.split('\n')
      row = []
      for cell, x in line.split(',')
        row.push(new Cell(cell, x, y))
      @cells.push(row)
    @cells.pop()
    window.k = @

  width: ->
    @cells.length

  height: ->
    @cells[0].length

  clear: ->
    for row, y in @cells
      for cell, x in row
        if cell.type() == 'NUMBER'
          cell.raw = ""

  toHtml: ->
    html = '<table class="col-sm-12">'
    for row in @cells
      html += '<tr>'
      for cell in row
        html += cell.render()
      html += '</tr>'
    html += '</table>'

  # column x, row y. Top left is (0, 0)
  rowLength: (x, y) ->
    totalCell = @rowTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    len = totalCell.x+1
    c = @cells[y][len]

    while c.type() == 'NUMBER'
      break unless c
      c = @cells[y][++len]


    return len - x - 1

  # column x, row y. Top left is (0, 0)
  colLength: (x, y) ->
    totalCell = @colTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    len = totalCell.y+1
    c = @cells[len][x]

    while c.type() == 'NUMBER'
      r = @cells[++len]
      break unless r
      c = r[x]

    return len - y - 1

  # rowTotal searches left from column x, row y returning the first total cell found.
  rowTotal: (x, y) ->
    c = @cells[y][x]
    c = @cells[y][x--] while c.type() != 'TOTAL'
    return c

  colTotal: (x, y) ->
    c = @cells[y][x]
    c = @cells[y--][x] while c.type() != 'TOTAL'
    return c

  domain: (x, y) ->


class Cell
  constructor: (text, x, y) ->
    @raw = text
    @x = x
    @y = y

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
          '<tr>' + '<td>' + @topRightStr() + '</td>' + '</tr>' +
          '<tr>' + '<td>' + @bottomLeftStr() + '</td>' + '</tr>' +
        '</table>' +
      '</td>'
    return '<td class="number">' + @number() + '</td>'

  topRight: ->
    s = parseInt @raw.split('-')[1]
    if !!s then parseInt s else 0

  bottomLeft: ->
    s = @raw.split('-')[0]
    if !!s then parseInt s else 0

  topRightStr: ->
    if @topRight() == 0 then "" else @topRight() + "&rarr;"

  bottomLeftStr: ->
    if @bottomLeft() == 0 then "" else @bottomLeft() + "&darr;"

  number: ->
    @raw
