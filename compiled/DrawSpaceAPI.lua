--[[

-- Types
	type Connection
		.Connected: boolean
		:Disconnect()

	type Signal
		:Fire(...)
		:Wait()
		:Once()
		:Connect(callback: (...) -> ()) -> Connection

	type DrawParams
		.Normal: Vector3,				default = Vector3.new(0, 1, 0)]
		.Transparency: number,				default = 0
		.PaintType: string,				default = 'Default'
		.Color: Color3,					default = Color3.new()
		.Size or .Width: number,			default = 0.2
		.Layer,						default = 1
		
		.Point or .Position: Vector3 			[required for Draw.Dot Action]
		.Points: {Vector3}				[required for Draw.Line Action]

	type StrokeSegment -- actually called pieces
		.Type: string
		.CFrame: CFrame
		.Size: Vector3

	type previewExtra: (uid: number, stroke: Stroke) -> ()  -- previewExtra is a callback that will be called when the stroke is drawn

	type PreviewArgs: { type: string, args: DrawParams, Layer: number, UID: number, Extra: previewExtra }

	type Stroke
		.Args: PreviewArgs
		.Params: DrawParams
		.Instance: Instance.Model
		.PartCount: number
		.Segments: {StrokeSegment}
		:Destroy()

	type Action
		.Action: {} -- will be sent to the server
		.Preview: PreviewArgs -- will be previewed to the client
		:Fire()
		:Queue()

	type Actions
		.Actions: {Action}
		:Add( action: Action )
		:Fire()
	
	type Drawing
		.Data: {Stroke}
		.Name: string
		:Clear()
		:SetStroke(uid: number, stroke: Stroke)
		:Save() -- saves to .../workspace/DrawSpaceSaves/FILENAME.ds
		:Draw()

-- Enums
	ActionTypes: -- ex: Manipulate.Delete, Draw.Line (not case sensitive)
		Draw:
			Dot(DrawParams: DrawParams, previewExtra: previewExtra)
			Line(DrawParams: DrawParams, previewExtra: previewExtra)
		Manipulate:
			Delete(args: {UIDs: {number}})
		Layer: -- this sometimes doesn't work (prob because server-sided compression)
			Create(name: string)
		Erase(uid: number)
		ClearAll()

	PaintTypes: -- if you dont have the gamepass for the paint type, these wont save (server-sided check)
		"Normal"
		"Neon"
		"Rainbow"
		"PerfectTransparency"
		"SuperShiny"
		
		"Neon_Rainbow"
		"PerfectTransparency_Rainbow"
		"SuperShiny_Rainbow"

--

-- DrawSpace is a global variable (can be used in any client script)

	DrawSpace.shouldFire = true
	DrawSpace.shouldPreview = true
	DrawSpace.Modules = {...} -- a table with all of the modules in game.ReplicatedStorage.PaintService.Modules

	DrawSpace:CreateAction(actionType: string, ...) -> Action
	DrawSpace:CreateActions() -> Actions
	DrawSpace:Queue(a: Action)
	DrawSpace:FireQueue()

	DrawSpace:ClearAll() -- shortcut to DrawSpace:CreateAction('clearall'):Fire()


	Drawspace.Preview.PartCount = 0
	Drawspace.Preview.Strokes = {} -- {Stroke}
	Drawspace.Preview.StrokeCreated = Signal(uid: number, stroke: Stroke)
	Drawspace.Preview.StrokeDestroyed = Signal(uid: number, stroke: Stroke)
	Drawspace.Preview.PaintFolder = Instance.Folder -- all generated strokes is parented to this

	Drawspace.Preview.NewStrokeClass(args: PreviewArgs)

	Drawspace.Preview:Preview(data: PreviewArgs)


	DrawSpace.CurrentDrawing = Drawing (default = nil)

	DrawSpace:NewLocalDrawing(name: string) -> Drawing
	DrawSpace:SaveCurrentDrawing(name: string) -- only strokes drawn by hand
	DrawSpace:LoadDrawing(path: string) -> Drawing


	DrawSpace.setDrawable(part: BasePart, drawable: boolean)
	DrawSpace:CreateInfiniteSpace() -- this will create a portal outside of spawn, enter it and it'll teleport you somewhere else
	DrawSpace:DestroyInfiniteSpace()
]]

if not DrawSpace then
	loadstring(game:GetService('HttpService'):JSONDecode(game:HttpGet("https://github.com/zildjibian/scripts/raw/main/inits.json")).DrawSpaceAPI)()
end

-- example script: https://github.com/zildjibian/scripts/raw/main/others/dsa.ex.lua
