$ ->

#   loadKakuro('kakuros/2016-01-08.txt')
  loadKakuro('kakuros/test.txt')

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
    # k.map((cell) -> console.log "x", cell.x, "y", cell.y, "domain", k.domain(cell.x, cell.y) if cell.type() == "NUMBER")
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

intersect = (arr1, arr2) -> toArray(toBitmask(arr1) & toBitmask(arr2))

neq = (one, two) -> one != two

arrayExcept = (arr, idx) ->
  res = arr[..]
  res.splice idx, 1
  res

permute = (arr) ->
  return [[]] if arr.length == 0

  permutations = (for value,idx in arr
    [value].concat perm for perm in permute arrayExcept arr, idx)

  # Flatten the array before returning it.
  [].concat permutations...

vals = (numOne, numTwo) -> (x, y) -> x != numOne || y == numTwo

class Kakuro
  constructor: (text) ->
    cells = []
    for line, y in text.split('\n')
      row = []
      for cell, x in line.split(',')
        c = new Cell(cell, x, y)
        row.push(c)
      cells.push(row)
    cells.pop()
    
    @cells = cells
    
    console.log(@cells)
    for line, y in cells
      for cell, x in line
        if cell.type() == 'NUMBER'
          cell.domain = @domain(x,y)
          cells[y][x] = cell
    @cells = cells
    window.k = @

  width: -> @cells[0].length

  height: -> @cells.length

  getCell: (x, y) ->
    console.assert(x >= 0)
    console.assert(y >= 0)
    console.assert(x < @width())
    console.assert(y < @height())

    return @cells[y][x]

  map: (f) ->
    for row, y in @cells
      for cell, x in row
        f(cell)

  clear: ->
    for row, y in @cells
      for cell, x in row
        if cell.type() == 'NUMBER'
          cell.raw = ""

  toHtml: ->
    html = '<table class="col-sm-12">'
    html += '<tr>'
    html += '<td></td>'
    for i in [0...@width()]
      html += "<td>#{i}</td>"
    html += '</tr>'
    for row, j in @cells
      html += '<tr>'
      html += "<td>#{j}</td>"
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
      c = @cells[y][++len]
      break unless c


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
    c = @getCell(x, y)
    c = @getCell(x, y--) until c.isTotal()
    return c

  domain: (x, y) ->
    rowPoss = ways(@rowTotal(x, y).topRight(), @rowLength(x, y)).reduce(((p, q) -> p.concat(q)), [])
    colPoss = ways(@colTotal(x, y).bottomLeft(), @colLength(x, y)).reduce(((p, q) -> p.concat(q)), [])

    intersect(rowPoss, colPoss)
  
  makeCSP: ->
    variables = {}
    constraints = []
    for row in @cells
      for cell in row
        if cell.isTotal()
          c = @makeConstraints(cell.x, cell.y)
          
          # c["constraints"] might be too big to splat.
          # constraints.concat(c["constraints"]...)
          constraints.push(x) for x in c["constraints"]
          if cell.isColTotal()
            variables[cell.string()+"c"] = c["colDomain"]
          if cell.isRowTotal()
            variables[cell.string()+"r"] = c["rowDomain"]
        if cell.isNumber()
          variables[cell.string()] = cell.domain
          
    csp = {}
    csp["variables"] = variables
    csp["constraints"] = constraints
    csp["cb"] = (assigned, unassigned, csp) ->
      console.log("assigned=", assigned, "unassigned=", unassigned)
    csp["timeStep"] = 1
    
    return csp
          
  
  makeConstraints: (x, y) ->
    c = @getCell(x, y)
    console.assert(c.isTotal())
    constraints = []

    if c.isRowTotal()
      
      rowAdd = @makeRowAddConstraints(x, y)
      rowDomain = rowAdd["domain"]
      rowConstraints = rowAdd["constraints"]
      constraints = constraints
          .concat(@makeRowNeqConstraints(x, y))
          .concat(rowConstraints)

    if c.isColTotal()
      colAdd = @makeColAddConstraints(x, y)
      colDomain = colAdd["domain"]
      colConstraints = colAdd["constraints"]
      constraints = constraints
          .concat(@makeColNeqConstraints(x, y))
          .concat(colConstraints)
    
    console.log("Created #{constraints.length} constraints for #{c.string()}")
    return (
      "constraints": constraints
      "rowDomain": rowDomain
      "colDomain": colDomain
    )

  makeRowNeqConstraints: (x, y) ->
    totalCell = @rowTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    constraints = []
    len = @rowLength(x, y)
    for i in [x+1...x+len]
      for j in [i+1..x+len]
        constraints.push([@cells[y][i].string(), @cells[y][j].string(), neq])
    return constraints

  makeColNeqConstraints: (x, y) ->
    totalCell = @colTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    constraints = []
    len = @colLength(x, y)
    for i in [y+1...y+len]
      for j in [i+1..y+len]
        constraints.push([@cells[i][x].string(), @cells[j][x].string(), neq])
    return constraints

  makeRowAddConstraints: (x, y) ->
    totalCell = @rowTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    len = @rowLength(x, y)
    waysArr = ways(totalCell.topRight(), len)
    allConstraints = []
    domain = []

    for way, k in waysArr
      permutations = permute(way)
      l = permutations.length
      for perm, j in permutations
        constraints = []
        valid = true
        for v, i in perm
          c = @getCell(x+i+1, y)
          if c.domain.indexOf(v) == -1
            valid = false
            break
          # console.log("Adding constraints: #{totalCell.string()} != #{k*l+j} || #{c.string()} == #{v}")
          constraints.push([totalCell.string()+"r", c.string(), vals(k*l+j, v)])
          
        if valid
          domain.push(k*l+j)
          allConstraints.push(constraints...)

    # console.log("Produced #{allConstraints.length} row constraints for #{totalCell.string()}")
    return (
      "domain": domain
      "constraints": allConstraints
    )

  makeColAddConstraints: (x, y) ->
    totalCell = @colTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    len = @colLength(x, y)
    waysArr = ways(totalCell.bottomLeft(), len)
    allConstraints = []
    domain = []

    for way, k in waysArr
      permutations = permute(way)
      l = permutations.length
      for perm, j in permutations
        constraints = []
        valid = true
        for v, i in perm
          c = @getCell(x, y+i+1)
          if c.domain.indexOf(v) == -1
            valid = false
            break
          # console.log("Adding constraints: #{totalCell.string()} != #{k*l+j} || #{c.string()} == #{v}")
          constraints.push([totalCell.string()+"c", c.string(), vals(k*l+j, v)])
        if valid
          domain.push(k*l+j)
          allConstraints.push(constraints...)
    
    # console.log("Produced #{allConstraints.length} col constraints for #{totalCell.string()}")
    return (
      "domain": domain
      "constraints": allConstraints
    )


class Cell
  constructor: (text, x, y, domain) ->
    @raw = text
    @x = x
    @y = y
    @domain = domain

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

  string: ->
    "(#{@x},#{@y})"
    
  isTotal: ->
    @type() == 'TOTAL'
  
  isNumber: ->
    @type() == 'NUMBER'
    
  isColTotal: ->
    @isTotal() && @bottomLeft() != 0
    
  isRowTotal: ->
    @isTotal() && @topRight() != 0
