export default function NotFound() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950 flex items-center justify-center p-4">
      <div className="text-center max-w-md">
        <div className="w-16 h-16 bg-emerald-500 rounded-2xl flex items-center justify-center mx-auto mb-6">
          <span className="text-white font-bold text-2xl">B</span>
        </div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
          Card not found
        </h1>
        <p className="text-gray-600 dark:text-gray-400 mb-8">
          This card may have been deactivated or the link is incorrect.
        </p>
        <a
          href="/"
          className="inline-block px-6 py-3 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl font-semibold transition-colors"
        >
          Create your own card
        </a>
      </div>
    </div>
  );
}
