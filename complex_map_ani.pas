//https://www.desmos.com/calculator/5cgjchjqg2
uses GraphWPF, helper;

type
  ParamMap = record
    Input: real;
    Output: Point;
    constructor create(input_: real; output_: Point);
    begin
      Input := Input_;
      Output := Output_;
    end;
  end;
  
  ComplexMap = record
    Input: Complex;
    Output: Complex;
    constructor create(input_, output_: Complex);
    begin
      Input := input_;
      Output := output_;
    end;
    
    function ToParamMapX := new ParamMap(Input.Real, pnt(Output.Real, Output.Imaginary));
    function ToParamMapY := new ParamMap(Input.Imaginary, pnt(Output.Real, Output.Imaginary));
  end;

const
  max_rec = 6;
  min_ang = cos(DegToRad(10));
  PlotPointsX = 15;
  PlotPointsY = 15;
  anim_length = 1 / 20;
  Width = 500;
  Height = 500;

var
  ViewRegion := Region.FromSize(20);
  PlotRegion := Region.FromSize(10);
  Step := Pnt(PlotRegion.Width / (PlotPointsX - 1), PlotRegion.Height / (PlotPointsY - 1));
  t: real := 0.0;
  pts := new ComplexMap[PlotPointsX, 2];

function f(z: complex) := z ** 2;

{function f(z: Complex) := cplx(
    16 * sin(z.Imaginary)**3,
    13 * cos(z.Imaginary) - 5 * cos(2*z.Imaginary) - 2*cos(3*z.Imaginary) - cos(4*z.Imaginary)
);}
//z*exp(cplx(0, DegToRad(90)))/z.Magnitude;

procedure PlotParametric(p1, p2, p3: ParamMap; f: real-> Point; depth: integer);
begin
  if (MathUtils.Angle(p1.Output, p2.Output, p3.Output) < min_ang) then 
  begin
    if (depth > 0) then
    begin
      dec(depth);
      var l_mid := (p1.Input + p2.Input) * 0.5;
      var r_mid := (p2.Input + p3.Input) * 0.5;
      PlotParametric(p1, new ParamMap(l_mid, f(l_mid)), p2, f, depth);
      PlotParametric(p2, new ParamMap(r_mid, f(r_mid)), p3, f, depth);
    end;
  end else
  begin
    var l1:=MathUtils.ClipLine(p1.Output,p2.Output,viewRegion);
    var l2:=MathUtils.ClipLine(p2.Output, p3.Output,viewRegion);
    if (l1.HasValue) then Line(l1.Value.p1, l1.Value.p2);
    if (l2.HasValue) then Line(l2.Value.p1, l2.Value.p2);
  end;    
end;

procedure PlotComplexMap(func: System.Func<Complex, Complex>);
begin
  var y := PlotRegion.Bottom;
  for var j := 0 to PlotPointsY - 1 do
  begin
    var x := PlotRegion.Left;
    for var i := 0 to PlotPointsX - 1 do
    begin
      var map := new ComplexMap(cplx(x, y), func(cplx(x, y)));
      var ind := j and 1;
      
      if (j >= 2) and (ind = 0) then
        PlotParametric(pts[i, 0].ToParamMapY(), pts[i, 1].ToParamMapY(), map.ToParamMapY(), v -> pnt(func(cplx(x, v))), max_rec);
      
      if (i >= 2) and ((i and 1 = 0)) then
        PlotParametric(pts[i - 2, ind].ToParamMapX(), pts[i - 1, ind].ToParamMapX(), map.ToParamMapX(), v -> pnt(func(cplx(v, y))), max_rec);
      
      pts[i, ind] := map;
      x += step.X;
    end;
    
    y += step.Y;
  end;
end;

procedure Anim(dt: real);
begin
  t += dt * anim_length;
  if (t >= 1) then begin t := 1; BeginFrameBasedAnimationTime(nil); end;
  PlotComplexMap(v -> MathUtils.lerp(v, f(v), t));
end;

begin
  Window.SetSize(Width, Height);
  Window.CenterOnScreen();
  ViewRegion:=ViewRegion.IncRatio(Window.Width/Window.Height);
  SetMathematicCoords(ViewRegion.Left, ViewRegion.Right, ViewRegion.Bottom, false);
  OnMouseDown += (x, y:real; mb: integer)-> println(x, y);
  BeginFrameBasedAnimationTime(Anim);
end.